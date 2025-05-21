import 'package:flutter/material.dart';
import 'chat_input_bar.dart';

/// Panel that slides up with attachment options.
class AttachmentPanel extends StatelessWidget {
  final bool visible;
  final Duration animationDuration;
  final void Function(AttachmentOption) onSelected;

  const AttachmentPanel({
    super.key,
    required this.visible,
    required this.animationDuration,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final height = visible ? 200.0 : 0.0;
    return AnimatedContainer(
      duration: animationDuration,
      height: height,
      child: visibilityWrapper(
        visible,
        Container(
          color: Colors.grey[100],
          child: GridView.count(
            crossAxisCount: 3,
            children: AttachmentOption.values.map((option) {
              final icon = _iconFor(option);
              final label = option.toString().split('.').last;
              return InkWell(
                onTap: () => onSelected(option),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 30),
                    SizedBox(height: 8),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget visibilityWrapper(bool visible, Widget child) {
    return ClipRect(
      child: Align(
        heightFactor: visible ? 1 : 0,
        child: child,
      ),
    );
  }

  IconData _iconFor(AttachmentOption option) {
    switch (option) {
      case AttachmentOption.photos:
        return Icons.photo;
      case AttachmentOption.camera:
        return Icons.camera_alt;
      case AttachmentOption.location:
        return Icons.location_on;
      case AttachmentOption.contacts:
        return Icons.contacts;
      case AttachmentOption.documents:
        return Icons.insert_drive_file;
    }
  }
}
