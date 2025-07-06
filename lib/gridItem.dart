// lib/widgets/file_grid_item.dart
import 'package:flutter/material.dart';

class FileGridItem extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const FileGridItem({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFolder = !name.contains('.') || name.endsWith('/');
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFolder ? Icons.folder : Icons.movie,
              size: 48,
              color: isFolder ? Colors.amber : Colors.blueGrey,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
