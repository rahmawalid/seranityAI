// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:ui_screens_grad/models/patient_model.dart';
// import 'package:ui_screens_grad/services/chatbot_service.dart';

// // ALIGNED: Using the same ChatMode enum from chatbot_service.dart
// enum ChatMode {
//   patientData,     // Chat with general patient data
//   patientSession,  // Chat with specific session data
//   appNavigation,   // App navigation help (coming soon)
// }

// // Helper extension to convert between ChatMode enums
// extension ChatModeConverter on ChatMode {
//   // Convert to the ChatService ChatMode
//   chatbot_service.ChatMode toServiceChatMode() {
//     switch (this) {
//       case ChatMode.patientData:
//         return chatbot_service.ChatMode.patientData;
//       case ChatMode.patientSession:
//         return chatbot_service.ChatMode.patientSession;
//       case ChatMode.appNavigation:
//         return chatbot_service.ChatMode.appNavigation;
//     }
//   }
// }

// class ChatWithPatientPage extends StatefulWidget {
//   final Patient patient;
//   final Session? specificSession;
//   final ChatMode chatMode;

//   const ChatWithPatientPage({
//     Key? key,
//     required this.patient,
//     this.specificSession,
//     this.chatMode = ChatMode.patientData,
//   }) : super(key: key);

//   @override
//   State<ChatWithPatientPage> createState() => _ChatWithPatientPageState();
// }

// class _ChatWithPatientPageState extends State<ChatWithPatientPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late ChatService _chatService;
//   late ChatMode _currentMode;
//   Session? _selectedSession;
//   bool _showingSessionSelection = false;
//   List<LocalChatMessage> _localMessages = [];

//   @override
//   void initState() {
//     super.initState();
//     _currentMode = widget.chatMode;
//     _selectedSession = widget.specificSession;
    
//     // Initialize chat service
//     _chatService = ChatService();
    
//     // Set up chat context
//     final patientId = _formatPatientId(widget.patient.patientID);
//     final sessionId = _selectedSession?.sessionId;
    
//     _chatService.setChatMode(
//       _currentMode.toServiceChatMode(),
//       patientId: patientId,
//       sessionId: sessionId,
//     );
    
//     // Add welcome message
//     _addWelcomeMessage();
    
//     // Listen to chat service changes
//     _chatService.addListener(_onChatServiceChanged);
//   }

//   @override
//   void dispose() {
//     _chatService.removeListener(_onChatServiceChanged);
//     _chatService.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   String _formatPatientId(int? patientId) {
//     if (patientId == null) return '';
//     return 'P$patientId';
//   }

//   void _onChatServiceChanged() {
//     setState(() {
//       // Update local messages from chat service
//       final serviceMessages = _chatService.getCurrentChatHistory();
//       _localMessages = serviceMessages.map((msg) => LocalChatMessage.fromService(msg)).toList();
//     });
//   }

//   void _addWelcomeMessage() {
//     final welcomeText = _getWelcomeMessage();
//     final welcomeMessage = LocalChatMessage(
//       id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
//       text: welcomeText,
//       isUser: false,
//       timestamp: DateTime.now(),
//       showModeButtons: _currentMode == ChatMode.patientData && _selectedSession == null,
//       isError: false,
//     );

//     setState(() {
//       _localMessages = [welcomeMessage];
//     });
//   }

//   String _getWelcomeMessage() {
//     switch (_currentMode) {
//       case ChatMode.patientData:
//         return "Hello! I'm SERNI and I'm your AI therapy assistant for ${widget.patient.personalInfo.fullName ?? 'this patient'}.\n\n"
//                "I can help you with different aspects of patient care. Please choose how you'd like to proceed:";
//       case ChatMode.patientSession:
//         return "Hi! I'm SERNI 🤖\n\nI'm focused on session ${_selectedSession?.sessionId} analysis for ${widget.patient.personalInfo.fullName}. "
//                "Ask me about session details, analysis results, or specific insights from this session.";
//       case ChatMode.appNavigation:
//         return "Hi! I'm SERNI 🤖\n\nApp navigation help is coming soon! I'll be able to guide you through app features and answer questions about how to use different tools.";
//     }
//   }

//   void _onModeSelected(ChatMode mode) {
//     setState(() {
//       _currentMode = mode;
//       _showingSessionSelection = false;
//     });

//     String userMessage = "";
//     String botResponse = "";

//     switch (mode) {
//       case ChatMode.patientData:
//         userMessage = "Patient Chat";
//         botResponse = "Great! I'm now ready to help you with overall patient analysis for ${widget.patient.personalInfo.fullName}. "
//                      "I can discuss their background, treatment progress, cross-session patterns, and provide general therapeutic guidance. "
//                      "What would you like to know about this patient?";
        
//         // Update chat service
//         _chatService.setChatMode(
//           mode.toServiceChatMode(),
//           patientId: _formatPatientId(widget.patient.patientID),
//         );
//         break;

//       case ChatMode.patientSession:
//         userMessage = "Session Chat";
//         if (widget.patient.sessions.isNotEmpty) {
//           botResponse = "Perfect! I can help you analyze specific therapy sessions. "
//                        "Please select which session you'd like to discuss:";
//           setState(() {
//             _showingSessionSelection = true;
//           });
//           return; // Don't add messages yet, wait for session selection
//         } else {
//           botResponse = "I'd love to help you with session analysis, but it looks like there are no recorded sessions for ${widget.patient.personalInfo.fullName} yet. "
//                        "Once you have session data, I'll be able to provide detailed insights about emotional patterns, therapeutic observations, and session-specific recommendations.";
//         }
//         break;

//       case ChatMode.appNavigation:
//         userMessage = "App Navigation Help";
//         botResponse = "App navigation help is coming soon! I'll be able to guide you through app features and answer questions about how to use different tools.";
//         break;
//     }

//     _addMessagePair(userMessage, botResponse);
//   }

//   void _onSessionSelected(Session session) {
//     setState(() {
//       _selectedSession = session;
//       _showingSessionSelection = false;
//     });

//     // Update chat service with session context
//     _chatService.setChatMode(
//       ChatMode.patientSession.toServiceChatMode(),
//       patientId: _formatPatientId(widget.patient.patientID),
//       sessionId: session.sessionId,
//     );

//     final userMessage = "Session ${session.sessionId} selected";
//     final botResponse = "Excellent! I'm now focused on session ${session.sessionId} for ${widget.patient.personalInfo.fullName}. "
//                        "This session was conducted on ${_formatDate(session.date)}. "
//                        "I can help you analyze the session data, emotional patterns, therapeutic progress, and provide specific insights. "
//                        "What would you like to know about this session?";

//     _addMessagePair(userMessage, botResponse);
//   }

//   void _addMessagePair(String userText, String botText) {
//     final now = DateTime.now();
//     final userMessage = LocalChatMessage(
//       id: 'user_${now.millisecondsSinceEpoch}',
//       text: userText,
//       isUser: true,
//       timestamp: now,
//       showModeButtons: false,
//       isError: false,
//     );

//     final botMessage = LocalChatMessage(
//       id: 'bot_${now.millisecondsSinceEpoch + 1}',
//       text: botText,
//       isUser: false,
//       timestamp: now.add(const Duration(milliseconds: 1)),
//       showModeButtons: false,
//       isError: false,
//     );

//     setState(() {
//       _localMessages.addAll([userMessage, botMessage]);
//     });

//     _scrollToBottom();
//   }

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'Unknown date';
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   Future<void> _sendMessage() async {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;

//     // Clear input
//     _messageController.clear();

//     // Add user message locally
//     final userMessage = LocalChatMessage(
//       id: 'user_${DateTime.now().millisecondsSinceEpoch}',
//       text: message,
//       isUser: true,
//       timestamp: DateTime.now(),
//       showModeButtons: false,
//       isError: false,
//     );

//     setState(() {
//       _localMessages.add(userMessage);
//     });

//     _scrollToBottom();

//     try {
//       // Send to chat service
//       final response = await _chatService.sendMessage(message);
      
//       if (response.success) {
//         // Service handles adding messages automatically via listener
//         _scrollToBottom();
//       }
//     } catch (e) {
//       // Add error message
//       final errorMessage = LocalChatMessage(
//         id: 'error_${DateTime.now().millisecondsSinceEpoch}',
//         text: 'Sorry, I encountered an error: ${e.toString()}',
//         isUser: false,
//         timestamp: DateTime.now(),
//         showModeButtons: false,
//         isError: true,
//       );

//       setState(() {
//         _localMessages.add(errorMessage);
//       });
//       _scrollToBottom();
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text(_getAppBarTitle()),
//         backgroundColor: _getModeColor(),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (_chatService.isLoading || _chatService.isTyping)
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: _getModeGradient(),
//             stops: const [0.0, 1.0],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Chat messages
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding: const EdgeInsets.all(16),
//                 itemCount: _localMessages.length + (_showingSessionSelection ? 1 : 0),
//                 itemBuilder: (context, index) {
//                   if (_showingSessionSelection && index == _localMessages.length) {
//                     return _buildSessionSelection();
//                   }
//                   return _buildMessageBubble(_localMessages[index]);
//                 },
//               ),
//             ),

//             // Input area
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(24),
//                   topRight: Radius.circular(24),
//                 ),
//               ),
//               child: SafeArea(
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: _getHintText(),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(24),
//                             borderSide: BorderSide.none,
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[100],
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 12,
//                           ),
//                         ),
//                         maxLines: null,
//                         textInputAction: TextInputAction.send,
//                         onSubmitted: (_) => _sendMessage(),
//                         enabled: _chatService.isReadyForChat() && !_showingSessionSelection,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     FloatingActionButton(
//                       onPressed: (_chatService.isReadyForChat() && 
//                                  !_showingSessionSelection && 
//                                  _messageController.text.trim().isNotEmpty) 
//                           ? _sendMessage 
//                           : null,
//                       backgroundColor: _getModeColor(),
//                       mini: true,
//                       child: const Icon(Icons.send, color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getAppBarTitle() {
//     final patientName = widget.patient.personalInfo.fullName ?? 'Patient';
//     switch (_currentMode) {
//       case ChatMode.patientData:
//         return 'Chat: $patientName';
//       case ChatMode.patientSession:
//         if (_selectedSession != null) {
//           return 'Session ${_selectedSession!.sessionId}: $patientName';
//         }
//         return 'Session Chat: $patientName';
//       case ChatMode.appNavigation:
//         return 'App Help';
//     }
//   }

//   Color _getModeColor() {
//     switch (_currentMode) {
//       case ChatMode.patientData:
//         return const Color(0xFF2F3C58);
//       case ChatMode.patientSession:
//         return const Color(0xFF5A6BFF);
//       case ChatMode.appNavigation:
//         return const Color(0xFF7C5FFB);
//     }
//   }

//   List<Color> _getModeGradient() {
//     switch (_currentMode) {
//       case ChatMode.patientData:
//         return [const Color(0xFFB7C6FF), const Color(0xFFE3F2FD)];
//       case ChatMode.patientSession:
//         return [const Color(0xFFE2E8F0), const Color(0xFFBEE3F8)];
//       case ChatMode.appNavigation:
//         return [const Color(0xFFEDF2F7), const Color(0xFFE2E8F0)];
//     }
//   }

//   String _getHintText() {
//     switch (_currentMode) {
//       case ChatMode.patientData:
//         return 'Ask about patient insights, therapeutic approaches...';
//       case ChatMode.patientSession:
//         return 'Ask about this session\'s insights...';
//       case ChatMode.appNavigation:
//         return 'Ask your navigation questions...';
//     }
//   }

//   Widget _buildMessageBubble(LocalChatMessage message) {
//     return Align(
//       alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.85,
//         ),
//         decoration: BoxDecoration(
//           color: message.isUser
//               ? _getModeColor()
//               : message.isError
//                   ? Colors.red.shade100
//                   : Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.text,
//               style: TextStyle(
//                 color: message.isUser ? Colors.white : Colors.black87,
//                 fontSize: 16,
//               ),
//             ),

//             // Mode selection buttons
//             if (message.showModeButtons) ...[
//               const SizedBox(height: 16),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: [
//                   _buildModeButton('Patient Chat', ChatMode.patientData, Icons.person),
//                   _buildModeButton('Session Chat', ChatMode.patientSession, Icons.psychology),
//                   _buildModeButton('App Help (Coming Soon)', ChatMode.appNavigation, Icons.help_outline),
//                 ],
//               ),
//             ],

//             const SizedBox(height: 4),
//             Text(
//               _formatTime(message.timestamp),
//               style: TextStyle(
//                 color: message.isUser ? Colors.white70 : Colors.grey.shade600,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildModeButton(String label, ChatMode mode, IconData icon) {
//     final isComingSoon = mode == ChatMode.appNavigation;
//     return ElevatedButton.icon(
//       onPressed: isComingSoon ? null : () => _onModeSelected(mode),
//       icon: Icon(icon, size: 16),
//       label: Text(label, style: const TextStyle(fontSize: 14)),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isComingSoon ? Colors.grey.shade300 : _getModeColor(),
//         foregroundColor: isComingSoon ? Colors.grey.shade600 : Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       ),
//     );
//   }

//   Widget _buildSessionSelection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Select a session to analyze:',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           ...widget.patient.sessions.map((session) => _buildSessionButton(session)).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSessionButton(Session session) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ElevatedButton(
//         onPressed: () => _onSessionSelected(session),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.grey.shade100,
//           foregroundColor: Colors.black87,
//           padding: const EdgeInsets.all(12),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.psychology, color: _getModeColor()),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Session ${session.sessionId}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   if (session.date != null)
//                     Text(
//                       _formatDate(session.date),
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTime(DateTime timestamp) {
//     return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
//   }
// }

// // Local message model for UI
// class LocalChatMessage {
//   final String id;
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;
//   final bool showModeButtons;
//   final bool isError;

//   LocalChatMessage({
//     required this.id,
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//     required this.showModeButtons,
//     required this.isError,
//   });

//   factory LocalChatMessage.fromService(chatbot_service.ChatMessage serviceMessage) {
//     return LocalChatMessage(
//       id: serviceMessage.id,
//       text: serviceMessage.content,
//       isUser: serviceMessage.isUser,
//       timestamp: serviceMessage.timestamp,
//       showModeButtons: false,
//       isError: false,
//     );
//   }
// }