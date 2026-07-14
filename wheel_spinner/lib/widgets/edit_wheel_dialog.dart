import 'package:flutter/material.dart';
import '../models/wheel_config.dart';

class EditWheelDialog extends StatefulWidget {
  final WheelConfig config;

  const EditWheelDialog({super.key, required this.config});

  @override
  State<EditWheelDialog> createState() => _EditWheelDialogState();
}

class _EditWheelDialogState extends State<EditWheelDialog> {
  late TextEditingController _nameController;
  late List<TextEditingController> _labelControllers;
  int _sectorCount = 6;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config.name);
    _sectorCount = widget.config.sectors.length;
    _labelControllers = widget.config.sectors
        .map((s) => TextEditingController(text: s.label))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _labelControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateSectorCount(int newCount) {
    if (newCount < 2 || newCount > 26) return;
    setState(() {
      if (newCount > _sectorCount) {
        // 增加扇区
        final newSectors = WheelConfig.generateSectors(newCount);
        // 保留旧标签
        for (int i = 0; i < _sectorCount; i++) {
          newSectors[i].label = _labelControllers[i].text;
        }
        _labelControllers = newSectors
            .map((s) => TextEditingController(text: s.label))
            .toList();
        widget.config.sectors = newSectors;
      } else if (newCount < _sectorCount) {
        // 减少扇区
        widget.config.sectors = widget.config.sectors.sublist(0, newCount);
        _labelControllers =
            _labelControllers.sublist(0, newCount);
      }
      _sectorCount = newCount;
    });
  }

  void _save() {
    widget.config.name = _nameController.text;
    for (int i = 0; i < widget.config.sectors.length; i++) {
      widget.config.sectors[i].label = _labelControllers[i].text;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑转盘'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '转盘名称'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('扇区数量：'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _sectorCount > 2
                      ? () => _updateSectorCount(_sectorCount - 1)
                      : null,
                ),
                Text('$_sectorCount'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _sectorCount < 26
                      ? () => _updateSectorCount(_sectorCount + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_sectorCount, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: widget.config.sectors[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _labelControllers[i],
                        decoration: InputDecoration(
                          labelText: '扇区 ${i + 1}',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
