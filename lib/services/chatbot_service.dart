import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';

/// Available chat modes for SERNI
enum ChatMode {
  patientData,     // Chat with general patient data
  patientSession,  // Chat with specific session data
  appNavigation,   // App navigation help (coming soon)
}

/// SERNI Chat Service - AI Chat/RAG functionality
/// Supports 3 chat modes:
/// 1. Patient Data Chat - General patient information
/// 2. Patient Session Chat - Specific session analysis  
/// 3. App Navigation Q&A - App help (coming soon)
class ChatService extends ChangeNotifier {
  
  // ================================
  // CHAT MODES & STATE
  // ================================
  
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  ChatMode _currentMode = ChatMode.patientData;
  String? _currentPatientId;
  int? _currentSessionId;
  
  // Chat history management
  final Map<String, List<ChatMessage>> _chatHistories = {};
  
  // Knowledge base status cache
  final Map<String, KnowledgeBaseStatus> _kbStatusCache = {};
  
  // ================================
  // GETTERS
  // ================================
  
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get error => _error;
  ChatMode get currentMode => _currentMode;
  String? get currentPatientId => _currentPatientId;
  int? get currentSessionId => _currentSessionId;
  
  // ================================
  // PRIVATE HELPERS
  // ================================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  String _getChatKey(String patientId, [int? sessionId]) {
    if (sessionId != null) {
      return '${patientId}_session_$sessionId';
    }
    return '${patientId}_general';
  }
  
  int _getNumericPatientId(String patientId) {
    if (patientId.startsWith('P')) {
      return int.parse(patientId.substring(1));
    }
    return int.parse(patientId);
  }

  // ================================
  // CHAT MODE MANAGEMENT
  // ================================
  
  /// Set chat mode and context
  void setChatMode(ChatMode mode, {String? patientId, int? sessionId}) {
    _currentMode = mode;
    _currentPatientId = patientId;
    _currentSessionId = sessionId;
    _clearError();
    notifyListeners();
  }
  
  /// Get current chat context description
  String getCurrentContextDescription() {
    switch (_currentMode) {
      case ChatMode.patientData:
        return _currentPatientId != null 
            ? 'Chatting about Patient $_currentPatientId general data'
            : 'Patient Data Chat Mode';
      case ChatMode.patientSession:
        return _currentPatientId != null && _currentSessionId != null
            ? 'Chatting about Patient $_currentPatientId, Session $_currentSessionId'
            : 'Patient Session Chat Mode';
      case ChatMode.appNavigation:
        return 'App Navigation Help (Coming Soon)';
    }
  }
  
  /// Check if current mode is ready for chat
  bool isReadyForChat() {
    switch (_currentMode) {
      case ChatMode.patientData:
        return _currentPatientId != null;
      case ChatMode.patientSession:
        return _currentPatientId != null && _currentSessionId != null;
      case ChatMode.appNavigation:
        return false; // Coming soon
    }
  }

  // ================================
  // MAIN CHAT FUNCTIONALITY
  // ================================
  
  /// Send message to SERNI and get response
  Future<ChatResponse> sendMessage(String message) async {
    if (!isReadyForChat()) {
      throw Exception('Chat context not set. Please select patient/session first.');
    }
    
    if (_currentMode == ChatMode.appNavigation) {
      throw Exception('App Navigation chat is coming soon!');
    }
    
    try {
      _setTyping(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(_currentPatientId!);
      final chatKey = _getChatKey(_currentPatientId!, _currentSessionId);
      
      // Get current chat history
      final history = _chatHistories[chatKey] ?? [];
      final historyForApi = history.map((msg) => msg.toApiFormat()).toList();
      
      // Prepare request based on mode
      String enhancedMessage = message;
      if (_currentMode == ChatMode.patientSession && _currentSessionId != null) {
        enhancedMessage = 'For session $_currentSessionId: $message';
      }
      
      // Make API call
      final uri = Uri.parse(ApiConstants.chatWithPatient(numericPatientId));
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': enhancedMessage,
          'history': historyForApi,
        }),
      );
      
      _setTyping(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final botResponse = responseData['response'] as String;
        final timestamp = DateTime.parse(responseData['timestamp'] as String);
        
        // Create chat messages
        final userMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: message,
          isUser: true,
          timestamp: DateTime.now(),
          mode: _currentMode,
        );
        
        final botMessage = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: botResponse,
          isUser: false,
          timestamp: timestamp,
          mode: _currentMode,
        );
        
        // Update chat history
        _chatHistories[chatKey] = [...history, userMessage, botMessage];
        notifyListeners();
        
        return ChatResponse(
          userMessage: userMessage,
          botMessage: botMessage,
          success: true,
        );
      } else {
        final errorData = jsonDecode(response.body);
        final error = errorData['error'] ?? 'Chat request failed';
        _setError(error);
        throw Exception(error);
      }
      
    } catch (e) {
      _setTyping(false);
      final error = 'Chat error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }
  
  /// Get chat history for current context
  List<ChatMessage> getCurrentChatHistory() {
    if (!isReadyForChat()) return [];
    
    final chatKey = _getChatKey(_currentPatientId!, _currentSessionId);
    return _chatHistories[chatKey] ?? [];
  }
  
  /// Clear chat history for current context
  void clearCurrentChatHistory() {
    if (!isReadyForChat()) return;
    
    final chatKey = _getChatKey(_currentPatientId!, _currentSessionId);
    _chatHistories.remove(chatKey);
    notifyListeners();
  }
  
  /// Clear all chat histories
  void clearAllChatHistories() {
    _chatHistories.clear();
    notifyListeners();
  }

  // ================================
  // KNOWLEDGE BASE MANAGEMENT
  // ================================
  
  /// Get knowledge base status for patient
  Future<KnowledgeBaseStatus> getKnowledgeBaseStatus(String patientId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getKnowledgeBaseStatus(numericPatientId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = KnowledgeBaseStatus.fromJson(responseData);
        
        // Cache the status
        _kbStatusCache[patientId] = status;
        
        return status;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get knowledge base status');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Knowledge base status error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }
  
  /// Rebuild knowledge base for patient
  Future<KnowledgeBaseStatus> rebuildKnowledgeBase(String patientId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.rebuildKnowledgeBase(numericPatientId));
      final response = await http.post(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = KnowledgeBaseStatus.fromRebuildResponse(responseData);
        
        // Update cache
        _kbStatusCache[patientId] = status;
        notifyListeners();
        
        return status;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to rebuild knowledge base');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Rebuild knowledge base error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }
  
  /// Clear knowledge base for patient
  Future<bool> clearKnowledgeBase(String patientId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.clearKnowledgeBase(numericPatientId));
      final response = await http.delete(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        // Remove from cache
        _kbStatusCache.remove(patientId);
        notifyListeners();
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear knowledge base');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Clear knowledge base error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }

  // ================================
  // CHAT CAPABILITIES & CONTEXT
  // ================================
  
  /// Get chat capabilities for patient
  Future<ChatCapabilities> getChatCapabilities(String patientId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getChatCapabilities(numericPatientId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatCapabilities.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get chat capabilities');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Chat capabilities error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }
  
  /// Get context preview for patient
  Future<ContextPreview> getContextPreview(String patientId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final numericPatientId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getContextPreview(numericPatientId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ContextPreview.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get context preview');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Context preview error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }

  // ================================
  // ADMIN OPERATIONS
  // ================================
  
  /// Rebuild all knowledge bases (admin only)
  Future<BatchOperationResult> rebuildAllKnowledgeBases() async {
    try {
      _setLoading(true);
      _clearError();
      
      final uri = Uri.parse(ApiConstants.rebuildAllKnowledgeBases);
      final response = await http.post(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Clear all cached statuses
        _kbStatusCache.clear();
        notifyListeners();
        
        return BatchOperationResult.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to rebuild all knowledge bases');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Batch rebuild error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }
  
  /// Clear all knowledge bases (admin only)
  Future<bool> clearAllKnowledgeBases() async {
    try {
      _setLoading(true);
      _clearError();
      
      final uri = Uri.parse(ApiConstants.clearAllKnowledgeBases);
      final response = await http.delete(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        // Clear all caches
        _kbStatusCache.clear();
        _chatHistories.clear();
        notifyListeners();
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear all knowledge bases');
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Clear all knowledge bases error: ${e.toString()}';
      _setError(error);
      throw Exception(error);
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================
  
  /// Check if patient has knowledge base
  Future<bool> hasKnowledgeBase(String patientId) async {
    try {
      final status = await getKnowledgeBaseStatus(patientId);
      return status.isBuilt;
    } catch (e) {
      return false;
    }
  }
  
  /// Get cached knowledge base status
  KnowledgeBaseStatus? getCachedKnowledgeBaseStatus(String patientId) {
    return _kbStatusCache[patientId];
  }
  
  /// Get chat mode display name
  String getChatModeDisplayName(ChatMode mode) {
    switch (mode) {
      case ChatMode.patientData:
        return 'Patient Data';
      case ChatMode.patientSession:
        return 'Session Analysis';
      case ChatMode.appNavigation:
        return 'App Help';
    }
  }
  
  /// Get SERNI greeting based on mode
  String getSerniGreeting() {
    switch (_currentMode) {
      case ChatMode.patientData:
        return "Hi! I'm SERNI 🤖\n\nI can help you explore and understand patient data. Ask me about symptoms, treatments, progress, or any patterns you'd like to analyze.";
      case ChatMode.patientSession:
        return "Hi! I'm SERNI 🤖\n\nI'm focused on session $_currentSessionId analysis. Ask me about session details, analysis results, or specific insights from this session.";
      case ChatMode.appNavigation:
        return "Hi! I'm SERNI 🤖\n\nApp navigation help is coming soon! I'll be able to guide you through app features and answer questions about how to use different tools.";
    }
  }
  

  @override
  void dispose() {
    _chatHistories.clear();
    _kbStatusCache.clear();
    super.dispose();
  }
}

// ================================
// DATA MODELS
// ================================

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMode mode;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.mode,
  });

  Map<String, dynamic> toApiFormat() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode.toString(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      mode: ChatMode.values.firstWhere(
        (mode) => mode.toString() == json['mode'],
        orElse: () => ChatMode.patientData,
      ),
    );
  }
}

/// Chat response model
class ChatResponse {
  final ChatMessage userMessage;
  final ChatMessage botMessage;
  final bool success;

  ChatResponse({
    required this.userMessage,
    required this.botMessage,
    required this.success,
  });
}

/// Knowledge base status model
class KnowledgeBaseStatus {
  final String patientId;
  final bool isBuilt;
  final int totalChunks;
  final Map<String, int> chunkTypes;
  final int totalSessions;
  final DateTime? lastUpdated;

  KnowledgeBaseStatus({
    required this.patientId,
    required this.isBuilt,
    required this.totalChunks,
    required this.chunkTypes,
    required this.totalSessions,
    this.lastUpdated,
  });

  factory KnowledgeBaseStatus.fromJson(Map<String, dynamic> json) {
    final kb = json['knowledge_base'] as Map<String, dynamic>;
    return KnowledgeBaseStatus(
      patientId: json['patient_id'].toString(),
      isBuilt: kb['status'] == 'built',
      totalChunks: kb['total_chunks'] ?? 0,
      chunkTypes: Map<String, int>.from(kb['chunk_types'] ?? {}),
      totalSessions: kb['total_sessions'] ?? 0,
      lastUpdated: kb['last_updated'] != null 
          ? DateTime.parse(kb['last_updated'])
          : null,
    );
  }

  factory KnowledgeBaseStatus.fromRebuildResponse(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return KnowledgeBaseStatus(
      patientId: json['patient_id'].toString(),
      isBuilt: stats['status'] == 'built',
      totalChunks: stats['total_chunks'] ?? 0,
      chunkTypes: Map<String, int>.from(stats['chunk_types'] ?? {}),
      totalSessions: stats['total_sessions'] ?? 0,
      lastUpdated: DateTime.parse(json['timestamp']),
    );
  }
}

/// Chat capabilities model
class ChatCapabilities {
  final String patientId;
  final bool hasPersonalInfo;
  final bool hasSessions;
  final bool hasAnalysisData;
  final int totalSessions;
  final List<String> availableDataTypes;

  ChatCapabilities({
    required this.patientId,
    required this.hasPersonalInfo,
    required this.hasSessions,
    required this.hasAnalysisData,
    required this.totalSessions,
    required this.availableDataTypes,
  });

  factory ChatCapabilities.fromJson(Map<String, dynamic> json) {
    return ChatCapabilities(
      patientId: json['patient_id'].toString(),
      hasPersonalInfo: json['has_personal_info'] ?? false,
      hasSessions: json['has_sessions'] ?? false,
      hasAnalysisData: json['has_analysis_data'] ?? false,
      totalSessions: json['total_sessions'] ?? 0,
      availableDataTypes: List<String>.from(json['available_data_types'] ?? []),
    );
  }
}

/// Context preview model
class ContextPreview {
  final String patientId;
  final KnowledgeBaseStatus knowledgeBaseStats;
  final List<ContextSample> sampleContext;

  ContextPreview({
    required this.patientId,
    required this.knowledgeBaseStats,
    required this.sampleContext,
  });

  factory ContextPreview.fromJson(Map<String, dynamic> json) {
    return ContextPreview(
      patientId: json['patient_id'].toString(),
      knowledgeBaseStats: KnowledgeBaseStatus.fromJson({
        'patient_id': json['patient_id'],
        'knowledge_base': json['knowledge_base_stats'],
      }),
      sampleContext: (json['sample_context'] as List)
          .map((item) => ContextSample.fromJson(item))
          .toList(),
    );
  }
}

/// Context sample model
class ContextSample {
  final String type;
  final String source;
  final String textPreview;
  final double similarity;

  ContextSample({
    required this.type,
    required this.source,
    required this.textPreview,
    required this.similarity,
  });

  factory ContextSample.fromJson(Map<String, dynamic> json) {
    return ContextSample(
      type: json['type'],
      source: json['source'],
      textPreview: json['text_preview'],
      similarity: json['similarity']?.toDouble() ?? 0.0,
    );
  }
}

/// Batch operation result model
class BatchOperationResult {
  final int totalPatients;
  final int successfullyRebuilt;
  final List<BatchError> errors;
  final DateTime timestamp;

  BatchOperationResult({
    required this.totalPatients,
    required this.successfullyRebuilt,
    required this.errors,
    required this.timestamp,
  });

  factory BatchOperationResult.fromJson(Map<String, dynamic> json) {
    return BatchOperationResult(
      totalPatients: json['total_patients'],
      successfullyRebuilt: json['successfully_rebuilt'],
      errors: (json['errors'] as List)
          .map((error) => BatchError.fromJson(error))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Batch operation error model
class BatchError {
  final String patientId;
  final String error;

  BatchError({
    required this.patientId,
    required this.error,
  });

  factory BatchError.fromJson(Map<String, dynamic> json) {
    return BatchError(
      patientId: json['patient_id'].toString(),
      error: json['error'],
    );
  }
}