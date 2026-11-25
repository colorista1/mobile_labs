import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const UnitConverterApp());
}

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвертер единиц измерения',
      debugShowCheckedModeBanner: false,

      // Ограничение ширины применяется ко всем экранам приложения.
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFF050814),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        primaryColor: const Color(0xFF8B5CF6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
          surface: const Color(0xFF111827),
          secondary: const Color(0xFF22D3EE),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111827),
          labelStyle: const TextStyle(
            color: Color(0xFFCBD5E1),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF8B5CF6),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFF87171),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFF87171),
              width: 1.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const List<UnitCategory> categories = [
    UnitCategory(
      name: 'Вес',
      icon: Icons.fitness_center,
      units: ['Грамм', 'Килограмм', 'Фунт', 'Дюйм'],
    ),
    UnitCategory(
      name: 'Валюта',
      icon: Icons.attach_money,
      units: ['USD', 'EUR', 'GBP'],
    ),
    UnitCategory(
      name: 'Температура',
      icon: Icons.thermostat,
      units: ['°C', '°F', 'K'],
    ),
    UnitCategory(
      name: 'Длина',
      icon: Icons.linear_scale,
      units: ['Метр', 'Километр', 'Миля', 'Дюйм'],
    ),
    UnitCategory(
      name: 'Площадь',
      icon: Icons.crop_square,
      units: ['М²', 'KM²', 'Mile²'],
    ),
    UnitCategory(
      name: 'Объем',
      icon: Icons.opacity,
      units: ['Литр', 'Галлон', 'М³'],
    ),
    UnitCategory(
      name: 'Время',
      icon: Icons.access_time,
      units: ['Секунда', 'Минута', 'Час'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Конвертер единиц измерения',
          style: TextStyle(fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = categories[index];

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(46),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category.icon,
                    color: const Color(0xFFB794F4),
                  ),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) {
                        return UnitConverterPage(category: category);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class UnitCategory {
  const UnitCategory({
    required this.name,
    required this.icon,
    required this.units,
  });

  final String name;
  final IconData icon;
  final List<String> units;
}

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({
    super.key,
    required this.category,
  });

  final UnitCategory category;

  @override
  State<UnitConverterPage> createState() => UnitConverterPageState();
}

class UnitConverterPageState extends State<UnitConverterPage> {
  String selectedUnit = '';
  String inputValue = '';
  String? errorMessage;

  Map<String, double> convertedValues = {};

  @override
  void initState() {
    super.initState();
    selectedUnit = widget.category.units.first;
  }

  void convertValue() {
    FocusScope.of(context).unfocus();

    setState(() {
      errorMessage = null;

      final parsedValue = double.tryParse(
        inputValue.replaceAll(',', '.'),
      );

      if (parsedValue == null || !parsedValue.isFinite) {
        errorMessage = 'Введите корректное число';
        convertedValues = {};
        return;
      }

      if (widget.category.name == 'Температура') {
        if (selectedUnit == '°C' && parsedValue < -273.15) {
          errorMessage = 'Минимальная температура: -273.15°C';
          convertedValues = {};
          return;
        }

        if (selectedUnit == '°F' && parsedValue < -459.67) {
          errorMessage = 'Минимальная температура: -459.67°F';
          convertedValues = {};
          return;
        }

        if (selectedUnit == 'K' && parsedValue < 0) {
          errorMessage = 'Минимальная температура: 0K';
          convertedValues = {};
          return;
        }
      }

      Map<String, double> nextValues = {};

      switch (widget.category.name) {
        case 'Вес':
          switch (selectedUnit) {
            case 'Грамм':
              nextValues = {
                'Килограмм': parsedValue / 1000,
                'Фунт': parsedValue * 0.00220462,
                'Дюйм': parsedValue / 25.4,
              };
              break;

            case 'Килограмм':
              nextValues = {
                'Грамм': parsedValue * 1000,
                'Фунт': parsedValue * 2.20462,
                'Дюйм': parsedValue / 0.0254,
              };
              break;

            case 'Фунт':
              nextValues = {
                'Грамм': parsedValue * 453.592,
                'Килограмм': parsedValue * 0.453592,
                'Дюйм': (parsedValue * 0.453592) / 25.4,
              };
              break;

            case 'Дюйм':
              nextValues = {
                'Грамм': parsedValue * 25.4,
                'Килограмм': parsedValue * 0.0254,
                'Фунт': parsedValue * 0.00220462 * 25.4,
              };
              break;
          }
          break;

        case 'Валюта':
          switch (selectedUnit) {
            case 'USD':
              nextValues = {
                'EUR': parsedValue * 0.85,
                'GBP': parsedValue * 0.72,
              };
              break;

            case 'EUR':
              nextValues = {
                'USD': parsedValue * 1.18,
                'GBP': parsedValue * 0.85,
              };
              break;

            case 'GBP':
              nextValues = {
                'USD': parsedValue * 1.39,
                'EUR': parsedValue * 1.18,
              };
              break;
          }
          break;

        case 'Температура':
          switch (selectedUnit) {
            case '°C':
              nextValues = {
                '°F': (parsedValue * 9 / 5) + 32,
                'K': parsedValue + 273.15,
              };
              break;

            case '°F':
              nextValues = {
                '°C': (parsedValue - 32) * 5 / 9,
                'K': (parsedValue + 459.67) * 5 / 9,
              };
              break;

            case 'K':
              nextValues = {
                '°C': parsedValue - 273.15,
                '°F': (parsedValue * 9 / 5) - 459.67,
              };
              break;
          }
          break;

        case 'Длина':
          switch (selectedUnit) {
            case 'Метр':
              nextValues = {
                'Километр': parsedValue * 0.001,
                'Миля': parsedValue * 0.000621371,
                'Дюйм': parsedValue * 39.3701,
              };
              break;

            case 'Километр':
              nextValues = {
                'Метр': parsedValue * 1000,
                'Миля': parsedValue * 0.621371,
                'Дюйм': parsedValue * 39370.1,
              };
              break;

            case 'Миля':
              nextValues = {
                'Метр': parsedValue * 1609.34,
                'Километр': parsedValue * 1.60934,
                'Дюйм': parsedValue * 63360,
              };
              break;

            case 'Дюйм':
              nextValues = {
                'Метр': parsedValue * 0.0254,
                'Километр': parsedValue * 0.0000254,
                'Миля': parsedValue * 0.0000157828,
              };
              break;
          }
          break;

        case 'Площадь':
          switch (selectedUnit) {
            case 'М²':
              nextValues = {
                'KM²': parsedValue * 0.000001,
                'Mile²': parsedValue * 3.86102e-7,
              };
              break;

            case 'KM²':
              nextValues = {
                'М²': parsedValue * 1000000,
                'Mile²': parsedValue * 0.386102,
              };
              break;

            case 'Mile²':
              nextValues = {
                'М²': parsedValue * 2589988.11,
                'KM²': parsedValue * 2.589988,
              };
              break;
          }
          break;

        case 'Объем':
          switch (selectedUnit) {
            case 'Литр':
              nextValues = {
                'Галлон': parsedValue * 0.264172,
                'М³': parsedValue * 0.001,
              };
              break;

            case 'Галлон':
              nextValues = {
                'Литр': parsedValue * 3.78541,
                'М³': parsedValue * 0.00378541,
              };
              break;

            case 'М³':
              nextValues = {
                'Литр': parsedValue * 1000,
                'Галлон': parsedValue * 264.172,
              };
              break;
          }
          break;

        case 'Время':
          switch (selectedUnit) {
            case 'Секунда':
              nextValues = {
                'Минута': parsedValue * 0.0166667,
                'Час': parsedValue * 0.000277778,
              };
              break;

            case 'Минута':
              nextValues = {
                'Секунда': parsedValue * 60,
                'Час': parsedValue * 0.0166667,
              };
              break;

            case 'Час':
              nextValues = {
                'Секунда': parsedValue * 3600,
                'Минута': parsedValue * 60,
              };
              break;
          }
          break;
      }

      convertedValues = nextValues;
    });
  }

  String formatValue(double value) {
    return value.toStringAsFixed(4).replaceFirst(
          RegExp(r'\.?0+$'),
          '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final entries = convertedValues.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 8),

            TextField(
              onChanged: (value) {
                setState(() {
                  inputValue = value;
                  errorMessage = null;
                  convertedValues = {};
                });
              },
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                signed: widget.category.name == 'Температура',
              ),
              inputFormatters: [
                DecimalInputFormatter(
                  allowNegative: widget.category.name == 'Температура',
                ),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'Введите значение',
                errorText: errorMessage,
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              isExpanded: true,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedUnit = value;
                  errorMessage = null;
                  convertedValues = {};
                });
              },
              decoration: const InputDecoration(
                labelText: 'Единица измерения',
              ),
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              items: widget.category.units.map((unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: convertValue,
              child: const Text('Конвертировать'),
            ),

            const SizedBox(height: 20),

            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            formatValue(entry.value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFB794F4),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({
    this.allowNegative = false,
  });

  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final pattern = allowNegative
        ? RegExp(r'^-?\d*[.,]?\d*$')
        : RegExp(r'^\d*[.,]?\d*$');

    if (pattern.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}