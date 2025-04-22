import 'package:flutter/material.dart';
import 'package:bookworm/model/Shelf.dart';
import 'package:bookworm/model/BookItem.dart';

class BookItemDialogUpdate extends StatefulWidget {
  final BookItem bookItem;

  const BookItemDialogUpdate({super.key, required this.bookItem});

  @override
  State<BookItemDialogUpdate> createState() => _BookItemDialogUpdateState();
}

class _BookItemDialogUpdateState extends State<BookItemDialogUpdate> {
  List<Shelf> shelves = [
    Shelf(id: 1, name: 'Shelf A', description: '', capacityLimit: 100, currentCount: 10, timeCreate: DateTime.now()),
    Shelf(id: 2, name: 'Shelf B', description: '', capacityLimit: 100, currentCount: 20, timeCreate: DateTime.now()),
  ];

  Shelf? selShelf;
  String status = 'available';
  String? damageUrl;

  @override
  void initState() {
    super.initState();
    selShelf = shelves.firstWhere((s) => s.id == widget.bookItem.shelfId, orElse: () => shelves.first);
    status = widget.bookItem.status;
    damageUrl = widget.bookItem.damageImage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Book Item'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Shelf>(
              value: selShelf,
              decoration: const InputDecoration(labelText: 'Shelf', border: OutlineInputBorder()),
              items: shelves.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (s) => setState(() => selShelf = s),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['available', 'borrowed', 'damaged', 'lost'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => status = s!),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Damage Image URL', border: OutlineInputBorder()),
              controller: TextEditingController(text: damageUrl),
              onChanged: (v) => damageUrl = v,
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: () {
          // Save mock, in real you'd call API
          Navigator.pop(context);
        }, child: const Text('SAVE')),
      ],
    );
  }
}
