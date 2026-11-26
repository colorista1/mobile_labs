import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

enum TaskFilter {
  all,
  completed,
  active,
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      var prefixLength = 0;
      while (prefixLength < newValue.text.length &&
          oldValue.text[prefixLength] == newValue.text[prefixLength]) {
        prefixLength++;
      }

      var suffixLength = 0;
      while (suffixLength < newValue.text.length - prefixLength &&
          oldValue.text[oldValue.text.length - suffixLength - 1] ==
              newValue.text[newValue.text.length - suffixLength - 1]) {
        suffixLength++;
      }

      final removedText = oldValue.text.substring(
        prefixLength,
        oldValue.text.length - suffixLength,
      );
      if (removedText == '.') {
        return newValue;
      }
    }

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final dateDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = StringBuffer();
    for (var index = 0; index < dateDigits.length; index++) {
      formatted.write(dateDigits[index]);
      if (index == 1 || index == 3) {
        formatted.write('.');
      }
    }

    final cursor = newValue.selection.isValid
        ? newValue.text
            .substring(0, newValue.selection.extentOffset)
            .replaceAll(RegExp(r'\D'), '')
            .length
        : dateDigits.length;
    final formattedCursor =
        cursor + (cursor >= 2 ? 1 : 0) + (cursor >= 4 ? 1 : 0);

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(
        offset: formattedCursor.clamp(0, formatted.length),
      ),
    );
  }
}

String _formatDateInput(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year.toString().padLeft(4, '0')}';

DateTime? _parseDateInput(String input) {
  if (!RegExp(r'^[\d.]+$').hasMatch(input)) {
    return null;
  }

  final digits = input.replaceAll('.', '');
  if (digits.length != 8) {
    return null;
  }

  final day = int.parse(digits.substring(0, 2));
  final month = int.parse(digits.substring(2, 4));
  final year = int.parse(digits.substring(4, 8));
  if (year < 1 || year > 9999) {
    return null;
  }

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

Future<DateTime?> _showDatePickerWithInput(
  BuildContext context,
  DateTime initialDate, {
  Key dateInputKey = const Key('date-picker-input'),
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _DatePickerDialog(
      initialDate: initialDate,
      dateInputKey: dateInputKey,
    ),
  );
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    required this.initialDate,
    required this.dateInputKey,
  });

  final DateTime initialDate;
  final Key dateInputKey;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selectedDate;
  late final TextEditingController _dateController;
  bool _dateInputValid = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _dateController = TextEditingController(
      text: _formatDateInput(widget.initialDate),
    );
  }

  void _updateEnteredDate(String value) {
    final date = _parseDateInput(value);
    setState(() {
      _dateInputValid = date != null;
      if (date != null) {
        _selectedDate = date;
      }
    });
  }

  void _selectCalendarDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateInputValid = true;
      _dateController.text = _formatDateInput(date);
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите дату'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(1),
                lastDate: DateTime(9999, 12, 31),
                onDateChanged: _selectCalendarDate,
              ),
              TextFormField(
                key: widget.dateInputKey,
                controller: _dateController,
                keyboardType: TextInputType.number,
                inputFormatters: [_DateInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Дата (ДД.ММ.ГГГГ)',
                  hintText: '25.11.3026',
                  helperText: 'Можно ввести дату вручную',
                ),
                onChanged: _updateEnteredDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _dateInputValid
              ? () => Navigator.pop(context, _selectedDate)
              : null,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6658D3)),
        scaffoldBackgroundColor: const Color(0xFFF6F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F6FA),
          foregroundColor: Color(0xFF20213A),
          elevation: 0,
        ),
      ),
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final appWidth = constraints.maxWidth.clamp(0.0, 420.0);
          return ColoredBox(
            color: const Color(0xFFE9E9EF),
            child: Center(
              child: SizedBox(
                width: appWidth,
                height: constraints.maxHeight,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
      home: TaskApp(),
    );
  }
}

class Task {
  Task(this.id, this.title, this.description, this.completed, this.dateTime);

  Task.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        completed = json['completed'],
        dateTime = DateTime.parse(json['dateTime']);

  String id;
  bool completed;
  String description;
  String title;
  DateTime dateTime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'dateTime': dateTime.toIso8601String(),
      };
}

class TaskApp extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _TaskAppState createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  List<Task> tasks = [];
  TaskFilter currentFilter = TaskFilter.all;
  DateTime? selectedDate;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    loadTasks();
    initializeNotifications();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();

    for (var task in tasks) {
      scheduleNotification(task);
    }
  }

  void scheduleNotification(Task task) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      'Receive task reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(task.dateTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void addTask(Task task) {
    setState(() {
      tasks.add(task);
      saveTasks();
    });
  }

  void editTask(Task editedTask) {
    setState(() {
      int index = tasks.indexWhere((task) => task.id == editedTask.id);
      if (index != -1) {
        tasks[index] = editedTask;
        saveTasks();
      }
    });
  }

  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getString('tasks');
    if (data != null) {
      var objs = jsonDecode(data) as List;
      setState(() {
        tasks = objs.map((obj) => Task.fromJson(obj)).toList();
      });
    }
  }

  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasks));
  }

  void deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
      saveTasks();
    });
  }

  List<Task> getFilteredTasks() {
    late final Iterable<Task> statusFilteredTasks;
    switch (currentFilter) {
      case TaskFilter.completed:
        statusFilteredTasks = tasks.where((task) => task.completed);
        break;
      case TaskFilter.active:
        statusFilteredTasks = tasks.where((task) => !task.completed);
        break;
      default:
        statusFilteredTasks = tasks;
    }

    final date = selectedDate;
    if (date == null) {
      return statusFilteredTasks.toList();
    }
    return statusFilteredTasks
        .where((task) => DateUtils.isSameDay(task.dateTime, date))
        .toList();
  }

  void setFilter(TaskFilter filter) {
    setState(() {
      currentFilter = filter;
    });
  }

  Future<void> _chooseDate() async {
    final date = await _showDatePickerWithInput(
      context,
      selectedDate ?? DateTime.now(),
      dateInputKey: const Key('main-date-picker-input'),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      selectedDate = date;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm'); // Формат времени

    final formattedDate = dateFormat.format(dateTime);
    final formattedTime = timeFormat.format(dateTime);

    return '$formattedDate в $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = getFilteredTasks();
    final completedCount = tasks.where((task) => task.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd.MM.yyyy')
                              .format(selectedDate ?? DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xFF85869A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Мои задачи',
                          style: TextStyle(
                            color: Color(0xFF20213A),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Выбрать дату',
                    onPressed: _chooseDate,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE9E6FB),
                      foregroundColor: const Color(0xFF6658D3),
                      fixedSize: const Size(46, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7164DE), Color(0xFF5548BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6658D3).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Твой прогресс',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tasks.isEmpty
                                ? 'Начни с малого ✨'
                                : '$completedCount из ${tasks.length} выполнено',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFB8F2D0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFD978),
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 25, 14, 11),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Список',
                      style: TextStyle(
                        color: Color(0xFF20213A),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selectedDate != null)
                    TextButton(
                      onPressed: () => setState(() => selectedDate = null),
                      child: const Text('Сбросить дату'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 43,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  FilterButton(
                    text: 'Все',
                    filter: TaskFilter.all,
                    currentFilter: currentFilter,
                    onFilterChanged: setFilter,
                  ),
                  FilterButton(
                    text: 'Активные',
                    filter: TaskFilter.active,
                    currentFilter: currentFilter,
                    onFilterChanged: setFilter,
                  ),
                  FilterButton(
                    text: 'Завершённые',
                    filter: TaskFilter.completed,
                    currentFilter: currentFilter,
                    onFilterChanged: setFilter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: Color(0xFFECEAF8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.checklist_rounded,
                                size: 36,
                                color: Color(0xFF6658D3),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tasks.isEmpty
                                  ? 'Пока нет задач'
                                  : 'Здесь пока пусто',
                              style: const TextStyle(
                                color: Color(0xFF20213A),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tasks.isEmpty
                                  ? 'Добавь первую и освободи мысли'
                                  : 'Попробуй выбрать другой фильтр',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF85869A),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF28284A)
                                    .withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTaskScreen(
                                    task: task,
                                    onEdit: editTask,
                                    onDelete: deleteTask,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        task.completed = !task.completed;
                                        saveTasks();
                                      });
                                    },
                                    child: Container(
                                      width: 25,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: task.completed
                                            ? const Color(0xFF6658D3)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: task.completed
                                              ? const Color(0xFF6658D3)
                                              : const Color(0xFFD4D4E0),
                                          width: 1.7,
                                        ),
                                      ),
                                      child: task.completed
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 17,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: task.completed
                                                ? const Color(0xFF9999A8)
                                                : const Color(0xFF292A40),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            decoration: task.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (task.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            task.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF85869A),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 14,
                                              color: Color(0xFF8A82D8),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _formatDateTime(task.dateTime),
                                              style: const TextStyle(
                                                color: Color(0xFF77788D),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFB5B5C3),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6658D3),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Новая задача',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                onAdd: addTask,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    required this.text,
    required this.filter,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final TaskFilter currentFilter;
  final TaskFilter filter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    final selected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onFilterChanged(filter),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF6658D3),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF77788D),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  final ValueChanged<Task> onAdd;

  AddTaskScreen({required this.onAdd});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime selectedDateTime = DateTime.now();

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy, HH:mm').format(dateTime);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E5EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E5EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6658D3), width: 1.5),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await _showDatePickerWithInput(
      context,
      selectedDateTime,
      dateInputKey: const Key('add-task-date'),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добавить задачу',
          style: TextStyle(
            color: Color(0xFF20213A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Заполни детали задачи',
                  style: TextStyle(
                    color: Color(0xFF85869A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Название'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Описание'),
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6E5EE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECEAF8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF6658D3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дата и время',
                              style: TextStyle(
                                color: Color(0xFF85869A),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(selectedDateTime),
                              style: const TextStyle(
                                color: Color(0xFF20213A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDateTime,
                        child: const Text('Выбрать'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      final task = Task(
                        DateTime.now().toString(),
                        _titleController.text,
                        _descriptionController.text,
                        false,
                        selectedDateTime,
                      );
                      widget.onAdd(task);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6658D3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Добавить задачу',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  EditTaskScreen(
      {required this.task, required this.onEdit, required this.onDelete});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    selectedDateTime = widget.task.dateTime;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy, HH:mm').format(dateTime);
  }

  Future<void> _selectDateTime() async {
    final date = await _showDatePickerWithInput(
      context,
      selectedDateTime,
      dateInputKey: const Key('edit-task-date'),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Text(
                  'Дата и время: ${_formatDateTime(selectedDateTime)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _selectDateTime,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Выбрать дату и время'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final editedTask = Task(
                          widget.task.id,
                          _titleController.text,
                          _descriptionController.text,
                          widget.task.completed,
                          selectedDateTime,
                        );
                        widget.onEdit(editedTask);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6658D3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onDelete(widget.task);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE9E6FB),
                        foregroundColor: const Color(0xFF6658D3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
