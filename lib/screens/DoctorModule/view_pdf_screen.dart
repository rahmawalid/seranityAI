import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewPDFScreen extends StatefulWidget {
  final String reportId;

  const ViewPDFScreen({Key? key, required this.reportId}) : super(key: key);

  @override
  State<ViewPDFScreen> createState() => _ViewPDFScreenState();
}

class _ViewPDFScreenState extends State<ViewPDFScreen> {
  Uint8List? pdfBytes;
  bool isLoading = true;
  bool downloadInProgress = false;
  final PdfViewerController _pdfController = PdfViewerController();
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/report/download/${widget.reportId}'),
      );
      if (response.statusCode == 200) {
        pdfBytes = response.bodyBytes;
      } else {
        throw Exception("Failed to load PDF (status ${response.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading PDF: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => downloadInProgress = true);
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) throw "Storage permission denied";

      final dir = await getDownloadsDirectory();
      final file = File('${dir!.path}/session_report_${widget.reportId}.pdf');
      await file.writeAsBytes(pdfBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download failed: $e")));
    } finally {
      setState(() => downloadInProgress = false);
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
                  const Expanded(
                    child: Text(
                      "Session Analysis Output",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    onPressed:
                        pdfBytes != null && !downloadInProgress ? _downloadPdf : null,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Session analysis generated report preview below:",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 10),

            // PDF Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pdfBytes == null
                        ? const Center(child: Text("Failed to load PDF"))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SfPdfViewer.memory(
                              pdfBytes!,
                              controller: _pdfController,
                              scrollDirection: PdfScrollDirection.vertical,
                              canShowScrollHead: true,
                              canShowScrollStatus: true,
                              onDocumentLoaded: (details) {
                                // ensure initial zoom is 100%
                                _pdfController.zoomLevel = 1.0;
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}