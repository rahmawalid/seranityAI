import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:ui_screens_grad/constants/endpoints.dart'; // <-- adjust this path if your file lives elsewhere

class ViewTranscriptionScreen extends StatefulWidget {
  final String transcriptionId;
  final String patientName;
  final int sessionId;

  const ViewTranscriptionScreen({
    Key? key,
    required this.transcriptionId,
    required this.patientName,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ViewTranscriptionScreen> createState() => _ViewTranscriptionScreenState();
}

class _ViewTranscriptionScreenState extends State<ViewTranscriptionScreen> {
  Uint8List? pdfBytes;
  bool isLoading = true;
  bool downloadInProgress = false;
  final PdfViewerController _pdfController = PdfViewerController();
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadTranscriptionPdf();
  }

  Future<void> _loadTranscriptionPdf() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse(ApiConstants.viewTranscription(widget.transcriptionId));
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          pdfBytes = response.bodyBytes;
        });
      }
    } catch (_) {
      // ignore — we’ll just show the “not available” placeholder
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _downloadTranscriptionPdf() async {
    if (pdfBytes == null) return;

    setState(() => downloadInProgress = true);
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) throw "Storage permission denied";

      final dir = await getDownloadsDirectory();
      final filename =
          'transcription_${widget.patientName}_session_${widget.sessionId}.pdf';
      final file = File('${dir!.path}/$filename');
      await file.writeAsBytes(pdfBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download failed: $e")));
    } finally {
      if (mounted) setState(() => downloadInProgress = false);
    }
  }

  void _updateZoom(double delta) {
    final newZoom = (_currentZoom + delta).clamp(1.0, 5.0);
    setState(() {
      _currentZoom = newZoom;
      _pdfController.zoomLevel = _currentZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Session Transcription",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${widget.patientName} - Session ${widget.sessionId}",
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () => _updateZoom(-0.25),
                  ),
                  Text("${(_currentZoom * 100).toInt()}%"),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () => _updateZoom(0.25),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: pdfBytes != null && !downloadInProgress
                        ? _downloadTranscriptionPdf
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3A59),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: downloadInProgress
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Download",
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "This transcription was automatically generated from the session audio/video recording.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // PDF Viewer or placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pdfBytes == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Transcription not available",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Upload an audio/video file to generate a transcription for this session.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SfPdfViewer.memory(
      pdfBytes!,
      controller: _pdfController,
      scrollDirection: PdfScrollDirection.vertical,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoaded: (details) {
        _pdfController.zoomLevel = 1.0;
      },
    );
  }
}
