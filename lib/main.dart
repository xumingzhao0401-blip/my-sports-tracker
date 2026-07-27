import 'dart:convert';
import 'package:flutter/material.dart';
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
        cardTheme: CardTheme(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomePage(),
    );
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

// ISO 8601 正确的周数计算
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

  // 固定的初始化 Mock 数据（带固定锚点日期）
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
          LogEntry(id: 'l5', date: anchor.subtract(const Duration(days: 6)), value: 20),
        ],
      ),
      ExerciseItem(
        id: 'ex_2',
        name: '跳绳',
        unit: '个',
        target: 1000,
        history: [
          LogEntry(id: 'l6', date: anchor.subtract(const Duration(days: 0)), value: 1000),
          LogEntry(id: 'l7', date: anchor.subtract(const Duration(days: 1)), value: 800),
          LogEntry(id: 'l8', date: anchor.subtract(const Duration(days: 3)), value: 1200),
        ],
      ),
      ExerciseItem(
        id: 'ex_3',
        name: '俯卧撑',
        unit: '个',
        target: 50,
        history: [
          LogEntry(id: 'l9', date: anchor.subtract(const Duration(days: 0)), value: 50),
          LogEntry(id: 'l10', date: anchor.subtract(const Duration(days: 1)), value: 40),
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

  @override
  void initState() {
    super.initState();
    _loadData();
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

  // 计算连续打卡天数
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

  // 某日综合完成状态 (2: 全部完成, 1: 部分完成, 0: 未打卡)
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
  // 弹窗逻辑 (Dialogs)
  // ------------------------------------------

  // 打卡弹窗（含输入校验与快捷增加按钮）
  void _showRecordDialog(ExerciseItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          void addValue(double delta) {
            double curr = double.tryParse(controller.text) ?? 0;
            controller.text = (curr + delta).toInt().toString();
          }

          return AlertDialog(
            title: Text('记录：${item.name} (${item.unit})'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '本次完成量',
                    suffixText: item.unit,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
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
                  if (val == null || val <= 0) {
                    _showSnackBar('请输入大于 0 的有效数值！');
                    return;
                  }
                  item.history.add(LogEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: _selectedDate,
                    value: val,
                  ));
                  _saveData();
                  Navigator.pop(context);
                  _showSnackBar('打卡成功！+ $val ${item.unit}');
                },
                child: const Text('打卡'),
              ),
            ],
          );
        });
      },
    );
  }

  // 添加/修改运动项目弹窗
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

  // 删除运动项目二次确认
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

  // 当日打卡明细列表 Modal
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
                              title: Text('+ ${log.value} ${item.unit}'),
                              subtitle: Text('记录 ID: ${log.id.substring(log.id.length - 4)}'),
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
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
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
          // 1. 顶部统计摘要面板 (Dashboard)
          _buildHeaderDashboard(completedToday),

          // 2. 2周视图滚动日历 (2-Week Calendar)
          Container(
            height: 165,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildTwoWeekCalendar(),
          ),

          // 3. 紧凑型运动项目列表
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
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final item = _exercises[index];
                      double todayDone = item.totalForDate(_selectedDate);
                      bool isFinished = item.isCompletedOn(_selectedDate);

                      return InkWell(
                        onLongPress: () => _confirmDeleteExercise(item),
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
                                // 高亮对勾图标
                                Icon(
                                  isFinished ? Icons.check_circle : Icons.circle_outlined,
                                  color: isFinished ? Colors.green : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),

                                // 中间：项目名称与进度
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

                                // 右侧极简图标操作组
                                IconButton(
                                  icon: const Icon(Icons.list_alt, size: 20),
                                  tooltip: '打卡明细',
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
        ],
      ),
    );
  }

  // 构建顶部摘要看板
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

  // 构建 2 周滚动日历
  Widget _buildTwoWeekCalendar() {
    final now = DateTime.now();
    List<DateTime> weekMondays = List.generate(10, (i) {
      int offset = i - 7;
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      return monday.add(Duration(days: offset * 7));
    });

    return ListView.builder(
      itemCount: weekMondays.length,
      itemBuilder: (context, index) {
        DateTime monday = weekMondays[index];
        int weekNum = getIsoWeekNumber(monday);
        int year = getIsoYear(monday);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$year年 第$weekNum周',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
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
                    child: Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
// 趋势图 BottomSheet 组件 (Trend Chart)
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

    // 对历史记录先按日期排序
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

// 经过 Bug 修复与图例增强的 CustomPainter
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

    // Bug 修复：除零异常保护
    if (maxVal <= 0) {
      maxVal = 10;
    } else {
      maxVal *= 1.25; // 顶部预留留白
    }

    final double chartTop = 15;
    final double chartBottom = size.height - 30;
    final double chartHeight = chartBottom - chartTop;

    // 绘制 Y 轴背景刻度线与刻度值
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

    // 绘制目标红虚线
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

    // 绘制折线与数据点
    double stepX = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;
    List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      double x = data.length == 1 ? size.width / 2 : i * stepX;
      double y = chartBottom - (data[i].value / maxVal * chartHeight);
      points.add(Offset(x, y));

      // X 轴日期标签
      TextPainter(
        text: TextSpan(text: data[i].key, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x - 12, chartBottom + 6));

      // 数据点数值
      TextPainter(
        text: TextSpan(
          text: '${data[i].value.toStringAsFixed(data[i].value % 1 == 0 ? 0 : 1)}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x - 8, y - 16));
    }

    // 连线
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

    // 绘制圆点
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
