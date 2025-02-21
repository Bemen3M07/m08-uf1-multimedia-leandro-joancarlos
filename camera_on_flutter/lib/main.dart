import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  // Inicializar las cámaras
  Future<void> _initializeCameras() async {
    final cameras = await availableCameras();
    setState(() {
      _cameras = cameras;
    });
  }

  final List<Widget> _screens = [
    const GalleryScreen(),
    const MusicPlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_cameras.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _screens.insert(0, CameraScreen(cameras: _cameras));

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Càmera'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Picture'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  String? _lastImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.cameras[_isFrontCamera ? 1 : 0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();

      // Verificar si el widget aún está montado antes de usar el BuildContext
      if (!mounted) return;

      setState(() {
        _lastImagePath = image.path;
      });

      // Mostrar el cuadro de diálogo si el widget sigue montado
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Foto Capturada"),
            content: Text("Guardada en: $_lastImagePath"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Usa un sistema de logging en lugar de print
      debugPrint("Error al tomar la foto: $e");
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    });
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Càmera'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                if (_lastImagePath != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(_lastImagePath!),
                  ),
                FloatingActionButton(
                  onPressed: _takePicture,
                  child: const Icon(Icons.camera),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picture'), centerTitle: true),
      body: const Center(child: Text('Gallery Screen')),
    );
  }
}

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Player'), centerTitle: true),
      body: const Center(child: Text('Music Player Screen')),
    );
  }
}
