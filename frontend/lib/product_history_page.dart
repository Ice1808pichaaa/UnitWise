import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hackathon/data/product_history.dart';
import 'package:hackathon/models/app_drawer.dart';

class ProductHistoryPage extends StatefulWidget {
  const ProductHistoryPage({super.key});

  @override
  State<ProductHistoryPage> createState() => _ProductHistoryPageState();
}

class _ProductHistoryPageState extends State<ProductHistoryPage> {
  List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ProductHistory.instance.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _deleteAt(int index) async {
    await ProductHistory.instance.removeAt(index);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This will permanently remove all saved items.'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromRGBO(3, 63, 99, 1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromRGBO(3, 63, 99, 1),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ProductHistory.instance.clear(); // removes all saved data
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All product history deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product History',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(3, 63, 99, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Delete all',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No saved products yet.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final text = _items[index];
                      return Card(
                        elevation: 2,
                        color: const Color.fromARGB(255, 96, 138, 195),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MarkdownBody(
                                  data: text, // render saved markdown
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                          Theme.of(context))
                                      .copyWith(
                                    p: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _deleteAt(index),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
