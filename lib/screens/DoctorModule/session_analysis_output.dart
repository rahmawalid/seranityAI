// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient_model.dart'; // FIXED: Correct import
import 'package:ui_screens_grad/services/report_service.dart';
import 'package:pdfx/pdfx.dart';

class SessionAnalysisOutputScreen extends StatefulWidget {
  final Patient patient;
  final int sessionId;
  final String report_id;

  const SessionAnalysisOutputScreen({
    Key? key,
    required this.patient,
    required this.sessionId,
    required this.report_id,
  }) : super(key: key);

  @override
  State<SessionAnalysisOutputScreen> createState() =>
      _SessionAnalysisOutputScreenState();
}

class _SessionAnalysisOutputScreenState
    extends State<SessionAnalysisOutputScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // FIXED: Use the correct method that exists in ReportService
      final pdfPath = await ReportService.downloadReportForViewing(widget.report_id);

      // Create PDF controller with the local file
      _pdfController = PdfController(
        document: PdfDocument.openFile(pdfPath),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load PDF: $e';
      });
      print('PDF loading error: $e'); // ADDED: Debug logging
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);

    try {
      // FIXED: Use the downloadReport method (you need to add this to ReportService)
      final downloadPath = await ReportService.downloadReport(
        widget.report_id,
        customFileName: 'session_analysis_${widget.patient.personalInfo.fullName}_${widget.sessionId}.pdf',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded to: ${downloadPath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Folder',
              textColor: Colors.white,
              onPressed: () {
                // You could add functionality to open the file manager here
                print('Downloaded to: $downloadPath');
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Download error: $e'); // ADDED: Debug logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _downloadReport,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB7C6FF), Color(0xFFB9F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400), // ADDED: Max width for better UX
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2F3C58),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title
                    const Expanded(
                      child: Text(
                        'Session Analysis Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F3C58),
                        ),
                      ),
                    ),

                    // ENHANCED: Download Button with better styling
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadReport,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3C58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: const Color(0xFF2F3C58).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ENHANCED: Patient and session info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient: ${widget.patient.personalInfo.fullName ?? "Unknown"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2F3C58),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Session ID: ${widget.sessionId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Report ID: ${widget.report_id.length > 8 ? "${widget.report_id.substring(0, 8)}..." : widget.report_id}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ADDED: Report status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Generated',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PDF Viewer
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF2F3C58),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading PDF report...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF2F3C58),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Failed to Load Report',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _loadPdf,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2F3C58),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _pdfController != null
                                ? PdfView(
                                    controller: _pdfController!,
                                    scrollDirection: Axis.vertical,
                                    physics: const BouncingScrollPhysics(),
                                    backgroundDecoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'PDF viewer not available',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}