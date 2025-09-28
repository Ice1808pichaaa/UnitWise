import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hackathon/data/product_history.dart';
import 'package:hackathon/models/app_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Product {
  Product({required this.name, List<XFile>? images})
      : images = images ?? <XFile>[];

  String name; 
  final List<XFile> images;
}

class ProductComparisonPage extends StatefulWidget {
  const ProductComparisonPage({super.key});

  @override
  State<ProductComparisonPage> createState() => _ProductComparisonPageState();
}

class _ProductComparisonPageState extends State<ProductComparisonPage>
    with TickerProviderStateMixin {
  static const int _maxProducts = 3;
  final _picker = ImagePicker();

  final List<Product> _products = [
    Product(name: 'product_1_images'),
    Product(name: 'product_2_images'),
  ];

  late final TabController _tabController;

  String? _resultText; 
  List<String>? _resultSections; 
  int? _chosenProductIndex; 
  String? _selectedDecisionText; 
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _renumberProducts() {
    for (int i = 0; i < _products.length; i++) {
      _products[i].name = 'product_${i + 1}_images';
    }
  }

  Future<void> _addPhoto(int productIndex) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from library'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final img = await _picker.pickImage(source: source);
      if (img != null) {
        setState(() => _products[productIndex].images.add(img));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removePhoto(int productIndex, int photoIndex) {
    setState(() => _products[productIndex].images.removeAt(photoIndex));
  }

  void _addProduct() {
    if (_products.length >= _maxProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 3 products reached')),
      );
      return;
    }
    setState(() {
      _products.add(Product(name: 'product_${_products.length + 1}_images'));
      _renumberProducts(); 
    });
  }

  void _removeProductSet(int productIndex) {
    if (_products.length <= 2) return; 
    setState(() {
      _products.removeAt(productIndex);
      _renumberProducts(); 
    });
  }

  String _extractPlainText(String body) {
    dynamic parsed;
    try {
      parsed = jsonDecode(body);
    } catch (_) {
      return body;
    }

    if (parsed is Map) {
      for (final key in ['analysis', 'text', 'result', 'data']) {
        final v = parsed[key];
        if (v is String) return v;
      }
      if (parsed.length == 1 && parsed.values.first is String) {
        return parsed.values.first as String;
      }
      return body; 
    }

    if (parsed is String) {
      try {
        final second = jsonDecode(parsed);
        if (second is String) return second;
      } catch (_) {}
      return parsed;
    }

    return body; 
  }

  Future<void> _onResultTap() async {
    final uri = Uri.parse(
        'https://advanced-product-analyzer-1-woi3h7q6zq-uc.a.run.app');

    final allEmpty = _products.every((p) => p.images.isEmpty);
    if (allEmpty) {
      setState(() {
        _resultText = 'No photos to send.';
      });
      _tabController.animateTo(1);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resultText = null;
      _resultSections = null; 
      _chosenProductIndex = null; 
      _selectedDecisionText = null; 
    });

    try {
      final req = http.MultipartRequest('POST', uri);
      req.headers['accept'] = 'application/json,text/plain;q=0.9,*/*;q=0.8';

      for (int i = 0; i < _products.length; i++) {
        final product = _products[i];
        if (product.images.isEmpty) continue;

        for (final x in product.images) {
          final bytes =
              await File(x.path).readAsBytes();
          req.files.add(
            http.MultipartFile.fromBytes(
              'product_${i + 1}_images',
              bytes,
              filename: x.name,
            ),
          );
        }
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final normalized = _extractPlainText(res.body);

        final sections = normalized
            .split(RegExp(r'\bsplit\b', caseSensitive: false))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        setState(() {
          _isSubmitting = false;
          if (sections.isNotEmpty) {
            _resultSections = sections; 
            _resultText = null;
          } else {
            _resultSections = null;
            _resultText = normalized; 
          }
        });
        _tabController.animateTo(1);
      } else {
        setState(() {
          _isSubmitting = false;
          _resultSections = null;
          _resultText = 'Upload failed (${res.statusCode})\n${res.body}';
        });
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _resultText = 'Upload error: $e';
      });
      _tabController.animateTo(1);
    }
  }

  String _withHardBreaks(String md) {
    return md.replaceAllMapped(RegExp(r'(?<!\n)\n(?!\n)'), (_) => '  \n');
  }

  Widget _productsContent() {
    final canAddMore = _products.length < _maxProducts;
    final canDeleteSet = _products.length > 2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "For each product, take two photos:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "1. The front of the product with the price.\n"
          "2. The nutrition facts label on the back.",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        for (int i = 0; i < _products.length; i++) ...[
          _ProductSection(
            index: i,
            product: _products[i],
            onAddPhoto: () => _addPhoto(i),
            onRemovePhoto: (photoIdx) => _removePhoto(i, photoIdx),
            canDeleteSet: canDeleteSet,
            onDeleteSet: () => _removeProductSet(i),
          ),
          const Divider(height: 24),
        ],

        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: canAddMore ? _addProduct : null,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          label: const Text(
            'Add more product',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color.fromRGBO(61, 90, 128, 1),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _onResultTap,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.assessment_outlined, color: Colors.white),
          label: Text(
            _isSubmitting ? 'Processing…' : 'Result',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color.fromRGBO(40, 102, 110, 1),
          ),
        )
      ],
    );
  }

  Widget _resultContent() {
    if (_isSubmitting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resultSections != null) {
      final sections = _resultSections!;
      final productCount = (sections.length - 1).clamp(0, 3);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (sections.isNotEmpty) ...[
            const SizedBox(height: 8),
            MarkdownBody(
              data: _withHardBreaks(sections[0]),
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],

          for (int i = 1; i < sections.length; i++) ...[
            const SizedBox(height: 6),
            Text(
              "Product $i",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            MarkdownBody(
              data: _withHardBreaks(sections[i]),
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (productCount > 0) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Which product did you decide to buy?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            for (int p = 1; p <= productCount; p++)
              RadioListTile<int>(
                value: p,
                groupValue: _chosenProductIndex,
                title: Text(
                  'Product $p',
                  style: const TextStyle(fontSize: 16),
                ),
                activeColor: const Color.fromRGBO(61, 90, 128, 1),
                dense: true,
                onChanged: (val) {
                  setState(() {
                    _chosenProductIndex = val;
                    _selectedDecisionText =
                        sections[p]; 
                  });
                },
              ),
            if (_chosenProductIndex != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveDecision, 
                    icon: const Icon(
                      Icons.save,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Save product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(61, 90, 128, 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      );
    }

    if (_resultText == null) {
      return const Center(child: Text('No result yet.'));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: SelectableText(
          _resultText!,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _saveDecision() async {
    if (_selectedDecisionText == null ||
        _selectedDecisionText!.trim().isEmpty) {
      return;
    }
    final added =
        await ProductHistory.instance.add(_selectedDecisionText!.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(added ? 'Saved to history' : 'Already in history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Comparison",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(3, 63, 99, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: const Color.fromRGBO(158, 202, 225, 1),
          dividerColor: const Color.fromRGBO(3, 63, 99, 1),
          unselectedLabelColor: Colors.white60,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              text: 'Products',
            ),
            Tab(text: 'Result'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _productsContent(),
          _resultContent(), 
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.index,
    required this.product,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.canDeleteSet,
    required this.onDeleteSet,
  });

  final int index;
  final Product product;
  final VoidCallback onAddPhoto;
  final void Function(int photoIndex) onRemovePhoto;
  final bool canDeleteSet;
  final VoidCallback onDeleteSet;

  @override
  Widget build(BuildContext context) {
    final uiLabel = 'Product ${index + 1}:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                uiLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              tooltip: 'Add photo',
              onPressed: onAddPhoto,
              icon: const Icon(Icons.camera_alt_outlined),
            ),
            if (canDeleteSet)
              IconButton(
                tooltip: 'Delete product set',
                onPressed: onDeleteSet,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (product.images.isEmpty)
          const Text('No photos yet', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int p = 0; p < product.images.length; p++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(product.images[p].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        height: 18,
                        width: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[400],
                        ),
                        child: IconButton(
                          onPressed: () => onRemovePhoto(p),
                          icon: const Icon(Icons.close,
                              size: 14, color: Colors.black),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
