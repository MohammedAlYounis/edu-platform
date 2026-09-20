import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../services/pdf_cache_service.dart';

/// عارض PDF موحّد لكل الدروس والاختبارات — بند 17 في التصميم:
/// فتح، صفحات متعددة، Zoom (pinch-to-zoom)، Scroll، Loading، Error Handling، Cache.
/// يستخدم pdfx (رخصة MIT، مفتوح المصدر بالكامل، لا يتطلب أي ترخيص تجاري).
class PdfViewerWidget extends ConsumerStatefulWidget {
  final String bucket; // 'lessons' أو 'exams'
  final String storagePath;
  final String title;

  const PdfViewerWidget({
    super.key,
    required this.bucket,
    required this.storagePath,
    required this.title,
  });

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  bool _hasError = false;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final File file = await ref.read(pdfCacheServiceProvider).getLocalFile(
            bucket: widget.bucket,
            storagePath: widget.storagePath,
          );

      final document = await PdfDocument.openFile(file.path);
      _controller?.dispose();
      _controller = PdfControllerPinch(document: Future.value(document));

      if (!mounted) return;
      setState(() {
        _totalPages = document.pagesCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_loading && !_hasError && _totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('$_currentPage / $_totalPages')),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError || _controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('تعذر تحميل الملف، تحقق من الاتصال وحاول مرة أخرى.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    return PdfViewPinch(
      controller: _controller!,
      onPageChanged: (page) => setState(() => _currentPage = page),
    );
  }
}
