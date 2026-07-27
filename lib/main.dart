import 'package:flutter/material.dart';

void main() {
  runApp(const SportsTrackerApp());
}

class SportsTrackerApp extends StatelessWidget {
  const SportsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日常运动打卡',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// 运动项目数据模型
class ExerciseItem {
  String name;      // 运动名称
  String unit;      // 单位（如：分钟、个）
  double target;    // 目标数值
  List<double> historyRecords; // 历史记录列表

  ExerciseItem({
    required this.name,
    required this.unit,
    required this.target,
    required this.historyRecords,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 默认初始化三个常见运动条目
  final List<ExerciseItem> _exercises = [
    ExerciseItem(name: '跑步', unit: '分钟', target: 30, historyRecords: [15, 20, 30, 25, 35]),
    ExerciseItem(name: '跳绳', unit: '个', target: 1000, historyRecords: [500, 800, 1000, 1200]),
    ExerciseItem(name: '俯卧撑', unit: '个', target: 50, historyRecords: [20, 30, 40, 50]),
  ];

  // 弹窗：添加新运动或修改目标
  void _showAddOrEditDialog({int? index}) {
    final nameController = TextEditingController(text: index != null ? _exercises[index].name : '');
    final unitController = TextEditingController(text: index != null ? _exercises[index].unit : '分钟');
    final targetController = TextEditingController(text: index != null ? _exercises[index].target.toString() : '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? '添加新运动项目' : '修改目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index == null)
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '运动名称 (如: 仰卧起坐)')),
            if (index == null)
              TextField(controller: unitController, decoration: const InputDecoration(labelText: '单位 (如: 个/分钟)')),
            TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '每日目标量')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                double targetVal = double.tryParse(targetController.text) ?? 0;
                if (index == null) {
                  if (nameController.text.isNotEmpty) {
                    _exercises.add(ExerciseItem(
                      name: nameController.text,
                      unit: unitController.text,
                      target: targetVal,
                      historyRecords: [],
                    ));
                  }
                } else {
                  _exercises[index].target = targetVal;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          )
        ],
      ),
    );
  }

  // 弹窗：打卡记一次数据
  void _showRecordDialog(int index) {
    final recordController = TextEditingController();
    final item = _exercises[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('记录：${item.name}'),
        content: TextField(
          controller: recordController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '本次完成数量 (${item.unit})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              double val = double.tryParse(recordController.text) ?? 0;
              if (val > 0) {
                setState(() {
                  item.historyRecords.add(val);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('打卡'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏃 每日运动记事本'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final item = _exercises[index];
          double latestRecord = item.historyRecords.isNotEmpty ? item.historyRecords.last : 0;
          double progress = item.target > 0 ? (latestRecord / item.target).clamp(0.0, 1.0) : 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddOrEditDialog(index: index),
                      )
                    ],
                  ),
                  Text('每日目标: ${item.target} ${item.unit} | 最新打卡: $latestRecord ${item.unit}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.show_chart),
                        label: const Text('查看数据趋势'),
                        onPressed: () => _showHistoryChart(context, item),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('打卡'),
                        onPressed: () => _showRecordDialog(index),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(),
        label: const Text('添加运动项目'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // 展示历史数据趋势的简易可视化页面
  void _showHistoryChart(BuildContext context, ExerciseItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.name} - 最近打卡记录', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              item.historyRecords.isEmpty
                  ? const Expanded(child: Center(child: Text('暂无记录，快去打卡吧！')))
                  : Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.historyRecords.length,
                        itemBuilder: (context, idx) {
                          double val = item.historyRecords[idx];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('$val${item.unit}'),
                                const SizedBox(height: 4),
                                Container(
                                  width: 30,
                                  height: (val / (item.target > 0 ? item.target : 100)) * 120,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(height: 4),
                                Text('第${idx + 1}次'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}