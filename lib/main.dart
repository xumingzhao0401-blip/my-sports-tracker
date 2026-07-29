import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SportsTrackerApp());
}

class SportsTrackerApp extends StatelessWidget {
  const SportsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '运动记事本 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ==========================================
// 毛主席语录数据库与轮换工具
// ==========================================

class MaoQuotes {
  static const List<String> quotes = [
    "文明其精神，野蛮其体魄。",
    "世上无难事，只要肯登攀。",
    "身体是革命的本钱。",
    "下定决心，不怕牺牲，排除万难，去争取胜利。",
    "发扬革命传统，争取更大光荣。",
    "雄关漫道真如铁，而今迈步从头越。",
    "自信人生二百年，会当水击三千里。",
    "一万年太久，只争朝夕。",
    "虚心使人进步，骄傲使人落后。",
    "风物长宜放眼量。",
    "星火燎原，勤学苦练。",
    "好好学习，天天向上。",
    "独有英雄驱虎豹，更无豪杰怕熊罴。",
    "苟日新，日日新，又日新。",
    "贵在坚持，重在积累，终生受益。",
  ];

  static String getQuoteForDate(DateTime date) {
    int dayIndex = (date.year * 365 + date.month * 31 + date.day);
    return quotes[dayIndex % quotes.length];
  }
}

// ==========================================
// 数据模型 (Data Models)
// ==========================================

class LogEntry {
  final String id;
  final DateTime date;
  double value;

  LogEntry({
    required this.id,
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'value': value,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.parse(json['date']),
        value: (json['value'] as num).toDouble(),
      );
}

class ExerciseItem {
  final String id;
  String name;
  String unit;
  double target;
  List<LogEntry> history;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.target,
    required this.history,
  });

  double totalForDate(DateTime date) {
    return history
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  bool isCompletedOn(DateTime date) {
    return totalForDate(date) >= target && target > 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'target': target,
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory ExerciseItem.fromJson(Map<String, dynamic> json) => ExerciseItem(
        id: json['id'],
        name: json['name'],
        unit: json['unit'],
        target: (json['target'] as num).toDouble(),
        history: (json['history'] as List)
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ==========================================
// 工具函数 (Utils)
// ==========================================

int getIsoWeekNumber(DateTime date) {
  DateTime thursday = date.add(Duration(days: 4 - date.weekday));
  DateTime firstDayOfYear = DateTime(thursday.year, 1, 1);
  int dayOfYear = thursday.difference(firstDayOfYear).inDays;
  return (dayOfYear / 7).floor() + 1;
}

int getIsoYear(DateTime date) {
  DateTime thursday = date.add(Duration(days: 4 - date.weekday));
  return thursday.year;
}

// ==========================================
// 本地存储服务 (Storage Service)
// ==========================================

class StorageService {
  static const String _storageKey = 'exercise_items_pro_v2';

  static Future<List<ExerciseItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) {
      final initialData = getMockInitialData();
      await saveItems(initialData);
      return initialData;
    }
    try {
      final List<dynamic> list = jsonDecode(rawJson);
      return list.map((e) => ExerciseItem.fromJson(e)).toList();
    } catch (e) {
      return getMockInitialData();
    }
  }

  static Future<void> saveItems(List<ExerciseItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String rawJson = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, rawJson);
  }

  static List<ExerciseItem> getMockInitialData() {
    final anchor = DateTime(2026, 7, 20);
    return [
      ExerciseItem(
        id: 'ex_1',
        name: '跑步',
        unit: '分钟',
        target: 30,
        history: [
          LogEntry(id: 'l1', date: anchor.subtract(const Duration(days: 0)), value: 30),
          LogEntry(id: 'l2', date: anchor.subtract(const Duration(days: 1)), value: 25),
          LogEntry(id: 'l3', date: anchor.subtract(const Duration(days: 2)), value: 35),
          LogEntry(id: 'l4', date: anchor.subtract(const Duration(days: 4)), value: 30),
        ],
      ),
      ExerciseItem(
        id: 'ex_2',
        name: '跳绳',
        unit: '个',
        target: 1000,
        history: [
          LogEntry(id: 'l5', date: anchor.subtract(const Duration(days: 0)), value: 1000),
          LogEntry(id: 'l6', date: anchor.subtract(const Duration(days: 1)), value: 800),
        ],
      ),
      ExerciseItem(
        id: 'ex_3',
        name: '俯卧撑',
        unit: '个',
        target: 50,
        history: [
          LogEntry(id: 'l7', date: anchor.subtract(const Duration(days: 0)), value: 50),
        ],
      ),
    ];
  }
}

// ==========================================
// 主页面 (Home Page)
// ==========================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ExerciseItem> _exercises = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  final int _pastWeeks = 50;
  final int _futureWeeks = 20;
  final double _weekRowHeight = 64.0;
  late ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController(
      initialScrollOffset: _pastWeeks * _weekRowHeight,
    );
    _loadData();
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await StorageService.loadItems();
    setState(() {
      _exercises = items;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await StorageService.saveItems(_exercises);
    setState(() {});
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  int _calculateStreak() {
    if (_exercises.isEmpty) return 0;
    DateTime checkDate = DateTime.now();
    int streak = 0;
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    while (true) {
      int completed = 0;
      for (var ex in _exercises) {
        if (ex.isCompletedOn(checkDate)) completed++;
      }
      if (completed == _exercises.length && _exercises.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (streak == 0 &&
            checkDate.year == DateTime.now().year &&
            checkDate.month == DateTime.now().month &&
            checkDate.day == DateTime.now().day) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  int _getDailyStatus(DateTime date) {
    if (_exercises.isEmpty) return 0;
    int completedCount = 0;
    int hasDataCount = 0;

    for (var ex in _exercises) {
      double val = ex.totalForDate(date);
      if (val >= ex.target && ex.target > 0) completedCount++;
      if (val > 0) hasDataCount++;
    }

    if (completedCount == _exercises.length) return 2;
    if (hasDataCount > 0) return 1;
    return 0;
  }

  // ------------------------------------------
  // 1. 日历长按快捷逻辑 (一键打卡/一键取消)
  // ------------------------------------------

  void _showCalendarDayLongPressMenu(DateTime day) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.year}年${day.month}月${day.day}日 快捷操作',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.done_all, color: Colors.green),
              title: const Text('一键全部打卡达标'),
              subtitle: const Text('将当日未达标的项目自动补全至目标值'),
              onTap: () {
                Navigator.pop(context);
                _checkInAllForDate(day);
              },
            ),
            ListTile(
              leading: const Icon(Icons.highlight_off, color: Colors.red),
              title: const Text('一键取消/清空当日所有打卡'),
              subtitle: const Text('移除当日所有项目的打卡记录'),
              onTap: () {
                Navigator.pop(context);
                _clearAllCheckInForDate(day);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _checkInAllForDate(DateTime day) {
    for (var ex in _exercises) {
      double current = ex.totalForDate(day);
      if (current < ex.target && ex.target > 0) {
        double needed = ex.target - current;
        ex.history.add(LogEntry(
          id: '${DateTime.now().millisecondsSinceEpoch}_${ex.id}',
          date: day,
          value: needed,
        ));
      }
    }
    _saveData();
    setState(() => _selectedDate = day);
    _showSnackBar('已为 ${day.month}月${day.day}日 一键全部打卡达标！');
  }

  void _clearAllCheckInForDate(DateTime day) {
    for (var ex in _exercises) {
      ex.history.removeWhere((e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);
    }
    _saveData();
    setState(() => _selectedDate = day);
    _showSnackBar('已清空 ${day.month}月${day.day}日 的所有打卡记录');
  }

  // ------------------------------------------
  // 2. 条目长按快捷逻辑 (一键取消/编辑/删除)
  // ------------------------------------------

  void _showItemLongPressMenu(ExerciseItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
              title: Text('一键取消 ${item.name} 当日打卡'),
              subtitle: Text('清除 ${_selectedDate.month}月${_selectedDate.day}日 的打卡记录'),
              onTap: () {
                Navigator.pop(context);
                _cancelTodayCheckIn(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.indigo),
              title: const Text('修改项目属性'),
              subtitle: const Text('调整目标量、名称或单位'),
              onTap: () {
                Navigator.pop(context);
                _showExerciseItemDialog(item: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除该运动项目'),
              subtitle: const Text('移除该项目及所有历史记录'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteExercise(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelTodayCheckIn(ExerciseItem item) {
    int beforeCount = item.history.length;
    item.history.removeWhere((e) =>
        e.date.year == _selectedDate.year &&
        e.date.month == _selectedDate.month &&
        e.date.day == _selectedDate.day);

    if (item.history.length < beforeCount) {
      _saveData();
      _showSnackBar('已取消 ${item.name} 当日打卡');
    } else {
      _showSnackBar('${item.name} 当日暂无打卡记录');
    }
  }

  // ------------------------------------------
  // 3. 格式化数据导出与导入逻辑
  // ------------------------------------------

  void _showExportImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_sharp, color: Colors.indigo),
              title: const Text('导出备份数据 (JSON)'),
              subtitle: const Text('将历史所有数据导出并复制到剪贴板保存'),
              onTap: () {
                Navigator.pop(context);
                _showExportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_sharp, color: Colors.green),
              title: const Text('导入恢复数据 (JSON)'),
              subtitle: const Text('粘贴 JSON 数据覆盖恢复'),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    String jsonStr = jsonEncode(_exercises.map((e) => e.toJson()).toList());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出备份数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请复制下方 JSON 文本保存备份：', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: jsonStr),
              maxLines: 6,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制到剪贴板'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(context);
              _showSnackBar('数据已成功复制到剪贴板！');
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入恢复数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请粘贴先前备份的 JSON 文本：', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '[{"id":"ex_1", ...}]',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              String input = controller.text.trim();
              if (input.isEmpty) {
                _showSnackBar('请输入 JSON 文本！');
                return;
              }
              try {
                final List<dynamic> list = jsonDecode(input);
                List<ExerciseItem> imported = list.map((e) => ExerciseItem.fromJson(e)).toList();
                setState(() {
                  _exercises = imported;
                });
                _saveData();
                Navigator.pop(context);
                _showSnackBar('数据恢复成功！已导入 ${imported.length} 个项目');
              } catch (e) {
                _showSnackBar('JSON 解析失败，请检查文本格式！');
              }
            },
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // 打卡与项目编辑弹窗
  // ------------------------------------------

  void _showRecordDialog(ExerciseItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          void addValue(double delta) {
            double curr = double.tryParse(controller.text) ?? 0;
            double newVal = curr + delta;
            controller.text = newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toString();
          }

          return AlertDialog(
            title: Text('记录/调整：${item.name} (${item.unit})'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '完成量 (正数增加 / 负数扣减)',
                    suffixText: item.unit,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(label: const Text('-10'), onPressed: () => addValue(-10)),
                    ActionChip(label: const Text('-5'), onPressed: () => addValue(-5)),
                    ActionChip(label: const Text('+5'), onPressed: () => addValue(5)),
                    ActionChip(label: const Text('+10'), onPressed: () => addValue(10)),
                    ActionChip(label: const Text('+20'), onPressed: () => addValue(20)),
                    ActionChip(
                      label: const Text('一键达标'),
                      onPressed: () {
                        double remaining = item.target - item.totalForDate(_selectedDate);
                        if (remaining > 0) controller.text = remaining.toInt().toString();
                      },
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              ElevatedButton(
                onPressed: () {
                  double? val = double.tryParse(controller.text);
                  if (val == null || val == 0) {
                    _showSnackBar('请输入有效数值！');
                    return;
                  }
                  item.history.add(LogEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: _selectedDate,
                    value: val,
                  ));
                  _saveData();
                  Navigator.pop(context);
                  _showSnackBar('打卡记录更新！${val > 0 ? "+$val" : val} ${item.unit}');
                },
                child: const Text('保存记录'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showExerciseItemDialog({ExerciseItem? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? '分钟');
    final targetCtrl = TextEditingController(text: item?.target.toString() ?? '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? '添加新运动项目' : '修改项目属性'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '运动名称 (如: 跑步)')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '计量单位 (如: 分钟/个)')),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每日目标量'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              String name = nameCtrl.text.trim();
              String unit = unitCtrl.text.trim();
              double? target = double.tryParse(targetCtrl.text);

              if (name.isEmpty || unit.isEmpty || target == null || target <= 0) {
                _showSnackBar('请填写正确的名称、单位与大于 0 的目标值！');
                return;
              }

              if (item == null) {
                _exercises.add(ExerciseItem(
                  id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  unit: unit,
                  target: target,
                  history: [],
                ));
              } else {
                item.name = name;
                item.unit = unit;
                item.target = target;
              }
              _saveData();
              Navigator.pop(context);
              _showSnackBar('保存成功！');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExercise(ExerciseItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除 ${item.name}？'),
        content: const Text('删除后该项目的所有历史打卡记录都将被移除，且无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _exercises.removeWhere((e) => e.id == item.id);
              _saveData();
              Navigator.pop(context);
              _showSnackBar('已删除 ${item.name}');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showDayDetailsModal(ExerciseItem item) {
    final dayLogs = item.history
        .where((e) =>
            e.date.year == _selectedDate.year &&
            e.date.month == _selectedDate.month &&
            e.date.day == _selectedDate.day)
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.name} - ${_selectedDate.month}月${_selectedDate.day}日 明细',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        _showRecordDialog(item);
                      },
                    )
                  ],
                ),
                const Divider(),
                Expanded(
                  child: dayLogs.isEmpty
                      ? const Center(child: Text('当日无打卡明细'))
                      : ListView.builder(
                          itemCount: dayLogs.length,
                          itemBuilder: (context, idx) {
                            final log = dayLogs[idx];
                            return ListTile(
                              title: Text('${log.value > 0 ? "+" : ""}${log.value} ${item.unit}'),
                              subtitle: Text('记录时间: ${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  item.history.removeWhere((e) => e.id == log.id);
                                  _saveData();
                                  setModalState(() {
                                    dayLogs.removeAt(idx);
                                  });
                                  _showSnackBar('记录已删除');
                                },
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------
  // 界面构建 (UI Build)
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    bool isSelectedToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    int completedToday = _exercises.where((e) => e.isCompletedOn(_selectedDate)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectedToday
            ? '🏃 运动记事本 Pro (今天)'
            : '🏃 运动记事本 (${_selectedDate.month}月${_selectedDate.day}日)'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '回到今天',
            onPressed: () {
              setState(() => _selectedDate = DateTime.now());
              _calendarScrollController.animateTo(
                _pastWeeks * _weekRowHeight,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: '数据备份与恢复',
            onPressed: _showExportImportMenu,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加项目',
            onPressed: () => _showExerciseItemDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 顶部统计看板
          _buildHeaderDashboard(completedToday),

          // 2. 滚动日历区域 (支持长按一键全打卡/取消)
          Container(
            height: 165,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildTwoWeekCalendar(),
          ),

          // 3. 紧凑型运动项目列表 (支持长按弹出菜单)
          Expanded(
            child: _exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('暂无运动项目，点击右上角➕添加'),
                        ElevatedButton(
                          onPressed: () => _showExerciseItemDialog(),
                          child: const Text('创建项目'),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final item = _exercises[index];
                      double todayDone = item.totalForDate(_selectedDate);
                      bool isFinished = item.isCompletedOn(_selectedDate);

                      return InkWell(
                        onLongPress: () => _showItemLongPressMenu(item),
                        child: Card(
                          elevation: isFinished ? 2 : 0.5,
                          color: isFinished ? Colors.green.shade50 : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isFinished ? Colors.green.shade300 : Colors.grey.shade300,
                              width: isFinished ? 1.5 : 0.8,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  isFinished ? Icons.check_circle : Icons.circle_outlined,
                                  color: isFinished ? Colors.green : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isFinished ? Colors.green.shade900 : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${todayDone.toInt()} / ${item.target.toInt()} ${item.unit}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isFinished ? Colors.green.shade800 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: item.target > 0 ? (todayDone / item.target).clamp(0.0, 1.0) : 0,
                                        backgroundColor: Colors.grey.shade200,
                                        color: isFinished ? Colors.green : Colors.indigoAccent,
                                        minHeight: 5,
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.list_alt, size: 20),
                                  tooltip: '明细',
                                  onPressed: () => _showDayDetailsModal(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.show_chart, size: 20, color: Colors.indigo),
                                  tooltip: '趋势图',
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => TrendChartSheet(item: item),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, size: 26, color: Colors.indigo),
                                  tooltip: '打卡',
                                  onPressed: () => _showRecordDialog(item),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 4. UI 底部毛主席语录激励面板
          _buildMaoQuoteBanner(),
        ],
      ),
    );
  }

  // 底部毛主席语录卡片
  Widget _buildMaoQuoteBanner() {
    String quote = MaoQuotes.getQuoteForDate(_selectedDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.amber.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.format_quote, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“ $quote ”',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '— 毛主席语录激励',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDashboard(int completedToday) {
    int streak = _calculateStreak();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('今日完成', '$completedToday / ${_exercises.length}', Icons.task_alt),
          Container(width: 1, height: 25, color: Colors.grey.shade400),
          _buildStatItem('连续达标', '$streak 天', Icons.local_fire_department, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.indigo),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildTwoWeekCalendar() {
    final now = DateTime.now();
    List<DateTime> weekMondays = List.generate(_pastWeeks + _futureWeeks, (i) {
      int offset = i - _pastWeeks;
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      return monday.add(Duration(days: offset * 7));
    });

    return ListView.builder(
      controller: _calendarScrollController,
      itemCount: weekMondays.length,
      itemBuilder: (context, index) {
        DateTime monday = weekMondays[index];
        DateTime sunday = monday.add(const Duration(days: 6));
        int weekNum = getIsoWeekNumber(monday);
        int year = getIsoYear(monday);

        String monthLabel = monday.month == sunday.month
            ? '${monday.month}月'
            : '${monday.month}月~${sunday.month}月';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$year年 $monthLabel (第$weekNum周)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (d) {
                  DateTime day = monday.add(Duration(days: d));
                  bool isSelected = day.year == _selectedDate.year &&
                      day.month == _selectedDate.month &&
                      day.day == _selectedDate.day;
                  int status = _getDailyStatus(day);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = day),
                    onLongPress: () => _showCalendarDayLongPressMenu(day),
                    child: Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? Colors.indigo : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (day.day == 1)
                            Text(
                              '${day.month}月',
                              style: const TextStyle(fontSize: 8, color: Colors.indigo, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 2),
                          if (status == 2)
                            const Icon(Icons.check_circle, size: 12, color: Colors.green)
                          else if (status == 1)
                            const Icon(Icons.pie_chart, size: 12, color: Colors.orange)
                          else
                            const Icon(Icons.circle_outlined, size: 12, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 趋势图 BottomSheet 组件
// ==========================================

class TrendChartSheet extends StatefulWidget {
  final ExerciseItem item;
  const TrendChartSheet({super.key, required this.item});

  @override
  State<TrendChartSheet> createState() => _TrendChartSheetState();
}

class _TrendChartSheetState extends State<TrendChartSheet> {
  bool _isByWeek = false;

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, double>> chartData = _processData();

    return Container(
      height: 420,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.item.name} - 历史趋势', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('按日')),
                  ButtonSegment(value: true, label: Text('按周')),
                ],
                selected: {_isByWeek},
                onSelectionChanged: (set) => setState(() => _isByWeek = set.first),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: chartData.isEmpty
                ? const Center(child: Text('暂无历史打卡记录'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: (chartData.length * 55.0).clamp(320.0, 2000.0),
                      padding: const EdgeInsets.only(right: 20, top: 10),
                      child: CustomPaint(
                        painter: LineChartPainter(chartData, widget.item.target, widget.item.unit),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _processData() {
    if (widget.item.history.isEmpty) return [];

    List<LogEntry> sorted = List.from(widget.item.history)..sort((a, b) => a.date.compareTo(b.date));
    Map<String, double> map = {};

    for (var log in sorted) {
      String key;
      if (_isByWeek) {
        int w = getIsoWeekNumber(log.date);
        int y = getIsoYear(log.date);
        key = '$y-W$w';
      } else {
        key = '${log.date.month}/${log.date.day}';
      }
      map[key] = (map[key] ?? 0) + log.value;
    }
    return map.entries.toList();
  }
}

class LineChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double target;
  final String unit;

  LineChartPainter(this.data, this.target, this.unit);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double maxVal = target;
    for (var e in data) {
      if (e.value > maxVal) maxVal = e.value;
    }

    if (maxVal <= 0) {
      maxVal = 10;
    } else {
      maxVal *= 1.25;
    }

    final double chartTop = 15;
    final double chartBottom = size.height - 30;
    final double chartHeight = chartBottom - chartTop;

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    int gridCount = 3;
    for (int i = 0; i <= gridCount; i++) {
      double y = chartBottom - (chartHeight * i / gridCount);
      double val = maxVal * i / gridCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(val >= 100 ? 0 : 1),
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(0, y - 10));
    }

    if (target > 0) {
      double targetY = chartBottom - (target / maxVal * chartHeight);
      final paintTarget = Paint()
        ..color = Colors.red.shade300
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      double dashWidth = 5, dashSpace = 3, startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, targetY), Offset(startX + dashWidth, targetY), paintTarget);
        startX += dashWidth + dashSpace;
      }

      TextPainter(
        text: TextSpan(
          text: '目标: ${target.toInt()} $unit',
          style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(size.width - 80, targetY - 14));
    }

    double stepX = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;
    List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      double x = data.length == 1 ? size.width / 2 : i * stepX;
      double y = chartBottom - (data[i].value / maxVal * chartHeight);
      points.add(Offset(x, y));

      TextPainter(
        text: TextSpan(text: data[i].key, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x - 12, chartBottom + 6));

      TextPainter(
        text: TextSpan(
          text: '${data[i].value.toStringAsFixed(data[i].value % 1 == 0 ? 0 : 1)}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x - 8, y - 16));
    }

    final paintLine = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paintLine);

    final paintDot = Paint()..color = Colors.indigo;
    final paintDotInner = Paint()..color = Colors.white;

    for (var p in points) {
      canvas.drawCircle(p, 4.5, paintDot);
      canvas.drawCircle(p, 2.0, paintDotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
