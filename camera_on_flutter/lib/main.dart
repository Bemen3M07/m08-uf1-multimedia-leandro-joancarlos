import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io'; // Importa la librería para trabajar con File.

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

  // Lista para almacenar las rutas de las imágenes capturadas
  List<String> _capturedImages = [];

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

  final List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    if (_cameras.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Asegurarse de que la pantalla de la cámara esté al principio
    if (_screens.isEmpty) {
      _screens.add(
          CameraScreen(cameras: _cameras, onImageCaptured: _onImageCaptured));
    }
    _screens.add(GalleryScreen(capturedImages: _capturedImages));

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

  // Callback para agregar imágenes capturadas
  void _onImageCaptured(String imagePath) {
    setState(() {
      _capturedImages.add(imagePath);
    });
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(String) onImageCaptured;

  const CameraScreen(
      {super.key, required this.cameras, required this.onImageCaptured});

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

      if (!mounted) return;

      setState(() {
        _lastImagePath = image.path;
      });

      widget.onImageCaptured(
          image.path); // Llamar al callback para actualizar la galería

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
            return Stack(
              children: [
                // Ajuste para que CameraPreview ocupe toda la pantalla
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                // Botón flotante
                Positioned(
                  bottom: 32,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _takePicture,
                    child: const Icon(Icons.camera),
                  ),
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
  final List<String> capturedImages;

  const GalleryScreen({super.key, required this.capturedImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picture'), centerTitle: true),
      body: capturedImages.isEmpty
          ? const Center(child: Text('No hay fotos capturadas'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemCount: capturedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.file(
                    File(capturedImages[index]),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
