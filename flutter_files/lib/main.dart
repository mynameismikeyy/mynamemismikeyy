import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// A list to store scan history locally
List<ScanHistoryItem> scanHistory = [];

// ------------------- FIRESTORE HELPER -------------------
Future<void> saveScanToFirestore(ScanHistoryItem item) async {
  try {
    final collection = FirebaseFirestore.instance.collection('scan_history');
    await collection.add({
      'name': item.name,
      'accuracy': item.accuracy,
      'date': item.date,
      'imagePath': item.imagePath,
      'isAsset': item.isAsset,
    });
    print('Scan saved to Firestore');
  } catch (e) {
    print('Error saving scan: $e');
  }
}

// ------------------- MY APP -------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Car',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFF97316),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Poppins',
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ------------------- LANDING PAGE -------------------
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Porsche_911_Carrera.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Top Bar
          SafeArea(child: _buildTopBar(context)),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sports Car',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Find your dream car.',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClassesListPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFF97316),
                child: Icon(Icons.flash_on, color: Colors.white),
              ),
              SizedBox(width: 10),
              Text(
                'Mikeyy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanPage()),
                  );
                },
                child: const Text(
                  'Scan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanHistoryPage(),
                    ),
                  );
                },
                child: const Text(
                  'History',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------- CLASSES LIST PAGE -------------------
class ClassesListPage extends StatelessWidget {
  const ClassesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Car Classes'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Sports Car Classes:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanPage()),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Proceed to Camera'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF007AFF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classItem = classes[index];
                  return Card(
                    color: const Color(0xFF2C2C2C),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          classItem.imagePath,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        classItem.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        classItem.description,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanPage(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
    );
  }
}

// ------------------- PROFILE PAGE -------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=a042581f4e29026704d',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mikeyy',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Car Enthusiast',
              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- SCAN PAGE -------------------
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];
  String _result = "";
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_unquant.tflite',
      );
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      setState(() {
        _labels = labelsData
            .split('\n')
            .where((label) => label.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _classifyImage(File image) async {
    if (_interpreter == null || _labels.isEmpty) return;
    final imageBytes = await image.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;
    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    var imageAsBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var input = List.generate(
      1,
      (index) => List.generate(
        224,
        (index) => List.generate(224, (index) => List.filled(3, 0.0)),
      ),
    );

    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        input[0][y][x][0] = (imageAsBytes[pixelIndex++] - 127.5) / 127.5;
        input[0][y][x][1] = (imageAsBytes[pixelIndex++] - 127.5) / 127.5;
        input[0][y][x][2] = (imageAsBytes[pixelIndex++] - 127.5) / 127.5;
      }
    }
    var output = List.generate(1, (index) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);
    final resultList = List<double>.from(output[0]);
    double maxConfidence = 0;
    int maxIndex = -1;
    for (int i = 0; i < resultList.length; i++) {
      if (resultList[i] > maxConfidence) {
        maxConfidence = resultList[i];
        maxIndex = i;
      }
    }

    final String resultName = maxIndex != -1
        ? _labels[maxIndex].replaceAll(RegExp(r'^\d+\s'), '')
        : "Unknown";

    final newHistoryItem = ScanHistoryItem(
      name: resultName,
      accuracy: 'Accuracy: ${(maxConfidence * 100).toStringAsFixed(2)}%',
      date: DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now()),
      imagePath: image.path,
      isAsset: false,
    );

    setState(() {
      _confidence = maxConfidence;
      _result = resultName;
      scanHistory.insert(0, newHistoryItem); // keep local
    });

    // Save to Firestore
    await saveScanToFirestore(newHistoryItem);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
        _result = "Classifying...";
        _confidence = 0.0;
      });
      await _classifyImage(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a Car')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFF97316)),
              child: Text(
                'Sports Car',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Scan with Camera'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Scan History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistic'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatisticPage(history: scanHistory),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take a Photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pick From Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _image == null
                        ? Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Text(
                                'No Image Selected',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : Image.file(
                            _image!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (_result.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.black.withOpacity(0.4),
                        ),
                        child: Center(
                          child: _result == "Classifying..."
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _result,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Accuracy: ${(_confidence * 100).toStringAsFixed(2)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- SCAN HISTORY ITEM -------------------
class ScanHistoryItem {
  final String name;
  final String accuracy;
  final String date;
  final String imagePath;
  final bool isAsset;

  ScanHistoryItem({
    required this.name,
    required this.accuracy,
    required this.date,
    required this.imagePath,
    this.isAsset = false,
  });
}

// ------------------- SCAN HISTORY PAGE -------------------
class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  void _deleteItem(int index) {
    setState(() {
      scanHistory.removeAt(index);
    });
  }

  void _clearHistory() {
    setState(() {
      scanHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _clearHistory),
        ],
      ),
      body: ListView.builder(
        itemCount: scanHistory.length,
        itemBuilder: (context, index) {
          final item = scanHistory[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: item.isAsset
                    ? Image.asset(
                        item.imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(item.imagePath),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${item.accuracy}\n${item.date}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteItem(index),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// ------------------- STATISTIC PAGE -------------------
class StatisticPage extends StatelessWidget {
  final List<ScanHistoryItem> history;
  const StatisticPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> stats = {};
    final Map<String, double> accuracyStats = {};
    for (var item in history) {
      stats[item.name] = (stats[item.name] ?? 0) + 1;
      accuracyStats[item.name] =
          (accuracyStats[item.name] ?? 0) +
          double.parse(
            item.accuracy.replaceAll('Accuracy: ', '').replaceAll('%', ''),
          );
    }

    final List<PieChartSectionData> pieChartSections = stats.entries.map((
      entry,
    ) {
      const fontSize = 16.0;
      const radius = 50.0;
      return PieChartSectionData(
        color:
            Colors.primaries[stats.keys.toList().indexOf(entry.key) %
                Colors.primaries.length],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();

    final List<BarChartGroupData> barChartGroups = accuracyStats.entries.map((
      entry,
    ) {
      return BarChartGroupData(
        x: accuracyStats.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value / (stats[entry.key] ?? 1),
            color: Colors.amber,
            width: 16,
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: stats.isEmpty
          ? const Center(
              child: Text(
                'No statistics yet. Start scanning!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total Scans',
                        history.length.toString(),
                        Icons.qr_code,
                      ),
                      _buildStatCard(
                        'Car Types',
                        stats.length.toString(),
                        Icons.directions_car,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan Distribution by Car',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieChartSections,
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Average Accuracy by Car',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barChartGroups,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final title = accuracyStats.keys.elementAt(
                                  value.toInt(),
                                );
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4.0,
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- DATA -------------------
class ClassItem {
  final String name;
  final String description;
  final String imagePath;

  const ClassItem({
    required this.name,
    required this.description,
    required this.imagePath,
  });
}

const List<ClassItem> classes = [
  ClassItem(
    name: 'Toyota GR Supra',
    description:
        'A high-performance Toyota sports car with a turbocharged engine.',
    imagePath: 'assets/images/TOYOTA_GR_SUPRA.jpg',
  ),
  ClassItem(
    name: 'Nissan GT-R',
    description: 'A legendary Japanese sports car known for its twin-turbo V6.',
    imagePath: 'assets/images/Nissan_GT-R.jpg',
  ),
  ClassItem(
    name: 'Ford Mustang',
    description: 'An iconic American sports car famous for its power.',
    imagePath: 'assets/images/Ford_Mustang.jpg',
  ),
  ClassItem(
    name: 'Chevrolet Camaro',
    description: 'A bold sports car offering strong performance.',
    imagePath: 'assets/images/Chevrolet_Camaro.jpg',
  ),
  ClassItem(
    name: 'Mazda MX-5 Miata',
    description: 'A lightweight roadster known for its excellent handling.',
    imagePath: 'assets/images/Mazda_MX-5_Miata.jpg',
  ),
  ClassItem(
    name: 'Subaru BRZ',
    description: 'A rear-wheel-drive coupe built for precision handling.',
    imagePath: 'assets/images/Subaru_BRZ.jpg',
  ),
  ClassItem(
    name: 'Honda Civic Type R',
    description: 'A high-performance hatchback with a track-focused design.',
    imagePath: 'assets/images/Honda_Civic_Type_R.jpg',
  ),
  ClassItem(
    name: 'Porsche 911 Carrera',
    description:
        'A luxury sports car combining performance and timeless design.',
    imagePath: 'assets/images/Porsche_911_Carrera.jpg',
  ),
  ClassItem(
    name: 'BMW Z4 Roadster',
    description: 'A premium convertible sports car with modern performance.',
    imagePath: 'assets/images/BMW_Z4_Roadster.jpg',
  ),
  ClassItem(
    name: 'Lamborghini Huracan',
    description: 'A V10-powered supercar with extreme performance and design.',
    imagePath: 'assets/images/Lamborghini_Huracan.jpg',
  ),
];
