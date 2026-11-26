import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the mobile task dashboard', (WidgetTester tester) async {
    await _pumpTodoApp(tester, const Size(390, 844));

    expect(find.text('Мои задачи'), findsOneWidget);
    expect(find.text('Твой прогресс'), findsOneWidget);
    expect(find.text('Пока нет задач'), findsOneWidget);
    expect(find.text('Новая задача'), findsOneWidget);
    expect(tester.getSize(find.byType(TaskApp)).width, 390);
  });

  testWidgets('keeps a phone-width layout on a wide screen',
      (WidgetTester tester) async {
    await _pumpTodoApp(tester, const Size(1280, 900));

    expect(tester.getSize(find.byType(TaskApp)).width, 420);
  });

  testWidgets('calendar filters tasks by the selected date',
      (WidgetTester tester) async {
    final today = DateTime.now();
    await _pumpTodoApp(
      tester,
      const Size(390, 844),
      initialPreferences: {
        'tasks': jsonEncode([
          _taskJson('today', 'Задача сегодня', today),
          _taskJson(
              'tomorrow', 'Задача завтра', today.add(const Duration(days: 1))),
        ]),
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Задача сегодня'), findsOneWidget);
    expect(find.text('Задача завтра'), findsOneWidget);

    await tester.tap(find.byTooltip('Выбрать дату'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    final dateInput = find.byKey(const Key('main-date-picker-input'));
    await tester.enterText(dateInput, '31122999');
    expect(
      tester.widget<TextFormField>(dateInput).controller!.text,
      '31.12.2999',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('31.12.2999'), findsOneWidget);
    expect(find.text('Задача сегодня'), findsNothing);
    expect(find.text('Задача завтра'), findsNothing);
  });

  testWidgets('add task uses the matching style and text time entry',
      (WidgetTester tester) async {
    await _pumpTodoApp(tester, const Size(390, 844));

    await tester.tap(find.text('Новая задача'));
    await tester.pumpAndSettle();
    expect(find.text('Заполни детали задачи'), findsOneWidget);

    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('date input adds separators and saves a distant year',
      (WidgetTester tester) async {
    await _pumpTodoApp(tester, const Size(390, 844));

    await tester.tap(find.text('Новая задача'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Задача на будущее');
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    final dateInput = find.byKey(const Key('add-task-date'));
    await tester.enterText(dateInput, '25');
    expect(
      tester.widget<TextFormField>(dateInput).controller!.text,
      '25.',
    );
    await tester.enterText(dateInput, '2511');
    expect(
      tester.widget<TextFormField>(dateInput).controller!.text,
      '25.11.',
    );
    await tester.enterText(dateInput, '25113026');

    final dateField = tester.widget<TextFormField>(
      dateInput,
    );
    expect(dateField.controller!.text, '25.11.3026');
    dateField.controller!.value = const TextEditingValue(
      text: '25.11.3026',
      selection: TextSelection.collapsed(offset: 6),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(dateField.controller!.text, '25.113026');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final addButton = find.byIcon(Icons.add_rounded);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final savedTasks = jsonDecode(preferences.getString('tasks')!) as List;
    final savedTask = savedTasks.single as Map<String, dynamic>;
    expect(DateTime.parse(savedTask['dateTime'] as String).year, 3026);
  });

  testWidgets('date input also works when editing a task',
      (WidgetTester tester) async {
    final today = DateTime.now();
    await _pumpTodoApp(
      tester,
      const Size(390, 844),
      initialPreferences: {
        'tasks':
            jsonEncode([_taskJson('existing', 'Существующая задача', today)]),
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Существующая задача'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать дату и время'));
    await tester.pumpAndSettle();
    final dateInput = find.byKey(const Key('edit-task-date'));
    await tester.enterText(dateInput, '25113026');
    expect(
      tester.widget<TextFormField>(dateInput).controller!.text,
      '25.11.3026',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final savedTasks = jsonDecode(preferences.getString('tasks')!) as List;
    final savedTask = savedTasks.single as Map<String, dynamic>;
    expect(DateTime.parse(savedTask['dateTime'] as String).year, 3026);
  });
}

Map<String, dynamic> _taskJson(String id, String title, DateTime dateTime) => {
      'id': id,
      'title': title,
      'description': '',
      'completed': false,
      'dateTime': dateTime.toIso8601String(),
    };

Future<void> _pumpTodoApp(
  WidgetTester tester,
  Size screenSize, {
  Map<String, Object> initialPreferences = const {},
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(initialPreferences);
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(notificationsChannel, (_) async => true);
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(notificationsChannel, null));

  await tester.pumpWidget(const TodoApp());
  await tester.pump();
}
