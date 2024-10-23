import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(FishTankApp());
}

class FishTankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FishTankScreen(),
    );
  }
}

class FishTankScreen extends StatefulWidget {
  @override
  _FishTankScreenState createState() => _FishTankScreenState();
}

class _FishTankScreenState extends State<FishTankScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  final List<Fish> _fishList = [];
  double _speed = 1.0;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) {
      _loadFishData();
    });
  }

  Future<void> _initDatabase() async {
    // Initialize SQLite database
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'fish_database.db');

    _database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE Fish(id INTEGER PRIMARY KEY, color TEXT, x REAL, y REAL)',
        );
      },
      version: 1,
    );
  }

  Future<void> _loadFishData() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps = await _database!.query('Fish');
    setState(() {
      _fishList.clear();
      for (var map in maps) {
        Fish loadedFish = Fish(
          color: Color(int.parse(map['color'], radix: 16)),
          x: map['x'],
          y: map['y'],
          angle: _random.nextDouble() * 360,
          animationController: AnimationController(
              vsync: this, duration: const Duration(seconds: 5))
            ..repeat(),
        );
        _fishList.add(loadedFish);
      }
    });
  }

  void _addFish(Color color) {
    if (_fishList.length >= 10) {
      return;
    }

    Fish newFish = Fish(
      color: color,
      x: _random.nextDouble() * 280,
      y: _random.nextDouble() * 280,
      angle: _random.nextDouble() * 360,
      animationController:
          AnimationController(vsync: this, duration: const Duration(seconds: 5))
            ..repeat(),
    );

    setState(() {
      _fishList.add(newFish);
    });
  }

  void _clearFish() {
    setState(() {
      _fishList.clear();
    });
  }

  void _saveFishData() async {
    if (_database == null) return;

    await _database!.delete('Fish');
    for (var fish in _fishList) {
      await _database!.insert(
        'Fish',
        fish.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  void dispose() {
    for (var fish in _fishList) {
      fish.animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fish Tank')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.teal[100],
              border: Border.all(
                color: Colors.brown,
                width: 5,
              ),
            ),
            child: Stack(
              children: _fishList
                  .map((fish) => AnimatedBuilder(
                        animation: fish.animationController,
                        builder: (context, child) {
                          fish.updatePosition(_speed);
                          return Positioned(
                            left: fish.x,
                            top: fish.y,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: fish.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ))
                  .toList(),
            ),
          ),
          Slider(
            value: _speed,
            min: 0,
            max: 5.0,
            label: 'Speed',
            onChanged: (value) {
              setState(() {
                _speed = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _clearFish,
                child: const Text('Clear Fish'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveFishData,
                child: const Text('Save Fish'),
              ),
            ],
          ),
          _buildColorGrid(),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.black,
      Colors.white,
      Colors.pink,
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: colors.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _addFish(colors[index]);
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors[index],
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Fish {
  Color color;
  double x;
  double y;
  double angle;
  final AnimationController animationController;

  Fish({
    required this.color,
    required this.x,
    required this.y,
    required this.angle,
    required this.animationController,
  });

  void updatePosition(double speed) {
    double radians = angle * (pi / 180);
    double movement = speed * 2;
    x += cos(radians) * movement;
    y += sin(radians) * movement;
    if (x <= 0 || x >= 280) {
      angle = _randomizeAngle();
      x = x.clamp(0.0, 280.0);
    }
    if (y <= 0 || y >= 280) {
      angle = _randomizeAngle();
      y = y.clamp(0.0, 280.0);
    }
  }

  double _randomizeAngle() {
    return Random().nextDouble() * 360;
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color.value.toRadixString(16),
      'x': x,
      'y': y,
    };
  }
}
