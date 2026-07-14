import 'package:flutter/material.dart';
import '../models/wheel_config.dart';
import '../services/storage_service.dart';
import '../widgets/spinning_wheel.dart';
import '../widgets/wheel_thumbnail.dart';
import '../widgets/edit_wheel_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WheelConfig> _configs = [];
  int _activeIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await StorageService.loadConfigs();
    setState(() {
      if (configs.isEmpty) {
        // 默认创建一个转盘
        _configs = [
          WheelConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: '默认转盘',
            sectors: WheelConfig.generateSectors(6),
          ),
        ];
      } else {
        _configs = configs;
      }
      _activeIndex = 0;
      _loading = false;
    });
    _save();
  }

  Future<void> _save() async {
    await StorageService.saveConfigs(_configs);
  }

  void _createNewWheel() {
    final newConfig = WheelConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '转盘 ${_configs.length + 1}',
      sectors: WheelConfig.generateSectors(6),
    );
    setState(() {
      _configs.add(newConfig);
      _activeIndex = _configs.length - 1;
    });
    _save();
  }

  void _deleteWheel(int index) {
    if (_configs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少保留一个转盘')),
      );
      return;
    }
    setState(() {
      _configs.removeAt(index);
      if (_activeIndex >= _configs.length) {
        _activeIndex = _configs.length - 1;
      }
    });
    _save();
  }

  Future<void> _editWheel() async {
    if (_configs.isEmpty) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditWheelDialog(config: _configs[_activeIndex]),
    );
    if (result == true) {
      setState(() {});
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeConfig =
        _configs.isNotEmpty ? _configs[_activeIndex] : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(activeConfig?.name ?? '转盘'),
        centerTitle: true,
        actions: [
          if (activeConfig != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editWheel,
              tooltip: '编辑转盘',
            ),
        ],
      ),
      body: Center(
        child: activeConfig != null
            ? SpinningWheel(
                key: ValueKey(activeConfig.id),
                config: activeConfig,
                size: MediaQuery.of(context).size.width * 0.85,
                onLongPress: _editWheel,
              )
            : const Text('请创建一个转盘'),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _configs.length + 1, // +1 为创建按钮
                itemBuilder: (context, index) {
                  if (index == _configs.length) {
                    // 创建按钮
                    return Center(
                      child: IconButton(
                        onPressed: _createNewWheel,
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.blue,
                        tooltip: '创建新转盘',
                      ),
                    );
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      WheelThumbnail(
                        config: _configs[index],
                        isSelected: index == _activeIndex,
                        onTap: () => setState(() => _activeIndex = index),
                      ),
                      // 删除按钮（长按缩略图出现，这里简化用右上角小X）
                      Positioned(
                        top: -4,
                        right: -2,
                        child: GestureDetector(
                          onTap: () => _deleteWheel(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
