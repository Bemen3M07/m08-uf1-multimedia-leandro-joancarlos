import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io'; // Importa la librería para trabajar con archivos del sistema.
import 'package:just_audio/just_audio.dart'; // Librería para reproducir audio.

void main() {
  runApp(const MyApp());
}

// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner:
          false, // Oculta la etiqueta de depuración en la app.
      home: MainScreen(), // Define la pantalla principal de la app.
    );
  }
}

// Pantalla principal de la aplicación con estado mutable
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

// Estado asociado a la pantalla principal
class MainScreenState extends State<MainScreen> {
  int _selectedIndex =
      0; // Índice de la pestaña seleccionada en la barra de navegación
  late List<CameraDescription> _cameras; // Lista de cámaras disponibles

  // Lista para almacenar las rutas de las imágenes capturadas
  List<String> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeCameras(); // Llama a la función para inicializar las cámaras
  }

  // Método para inicializar las cámaras disponibles en el dispositivo
  Future<void> _initializeCameras() async {
    final cameras = await availableCameras(); // Obtiene las cámaras disponibles
    setState(() {
      _cameras = cameras; // Asigna la lista de cámaras obtenidas
    });
  }

  // Lista de pantallas que se mostrarán en la app (se llenará dinámicamente)
  final List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    // Si aún no se han cargado las cámaras, muestra un indicador de carga
    if (_cameras.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si la lista de pantallas aún no ha sido inicializada, la llenamos con los widgets correspondientes
    if (_screens.isEmpty) {
      _screens.add(CameraScreen(
          cameras: _cameras,
          onImageCaptured: _onImageCaptured)); // Pantalla de la cámara
      _screens.add(GalleryScreen(
          capturedImages: _capturedImages)); // Pantalla de la galería
      _screens
          .add(const MusicPlayerScreen()); // Pantalla del reproductor de música
    }

    return Scaffold(
      body: _screens[_selectedIndex], // Muestra la pantalla seleccionada
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Càmera'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Picture'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        ],
        currentIndex: _selectedIndex, // Índice de la pestaña actual
        onTap: _onItemTapped, // Maneja el cambio de pantalla al tocar un icono
      ),
    );
  }

  // Método para cambiar la pestaña seleccionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Cambia el índice de la pantalla activa
    });
  }

  // Método para agregar imágenes capturadas a la galería
  void _onImageCaptured(String imagePath) {
    setState(() {
      _capturedImages.add(imagePath); // Agrega la ruta de la imagen a la lista
    });
  }
}

// Widget de pantalla de la cámara, que recibe la lista de cámaras y un callback para capturar imágenes
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras; // Lista de cámaras disponibles
  final Function(String)
      onImageCaptured; // Función callback para enviar la imagen capturada

  const CameraScreen(
      {super.key, required this.cameras, required this.onImageCaptured});

  @override
  CameraScreenState createState() => CameraScreenState();
}

// Estado de la pantalla de la cámara
class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller; // Controlador de la cámara
  late Future<void>
      _initializeControllerFuture; // Futuro para la inicialización de la cámara
  bool _isFlashOn = false; // Estado del flash (activado/desactivado)
  bool _isFrontCamera = false; // Indica si la cámara frontal está activa
  String? _lastImagePath; // Almacena la última imagen capturada

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Inicializa la cámara al cargar el widget
  }

  // Método para inicializar la cámara con la configuración adecuada
  void _initializeCamera() {
    _controller = CameraController(
      widget.cameras[_isFrontCamera ? 1 : 0], // Usa la cámara trasera o frontal
      ResolutionPreset.high, // Configura la resolución de la cámara
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return; // Verifica si el widget sigue en pantalla
      setState(() {}); // Refresca la UI tras inicializar la cámara
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera los recursos de la cámara al salir
    super.dispose();
  }

  // Método para tomar una foto
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture; // Asegura que la cámara está lista

      final image = await _controller.takePicture(); // Captura la imagen

      if (!mounted) return;

      setState(() {
        _lastImagePath = image.path; // Guarda la ruta de la imagen
      });

      widget.onImageCaptured(
          image.path); // Llama al callback para actualizar la galería

      if (mounted) {
        // Muestra un cuadro de diálogo con la ruta de la imagen capturada
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
      debugPrint(
          "Error al tomar la foto: $e"); // Muestra un error si la captura falla
    }
  }

  // Método para activar o desactivar el flash
  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn; // Alterna el estado del flash
      _controller.setFlashMode(
        _isFlashOn
            ? FlashMode.torch
            : FlashMode.off, // Activa o desactiva el flash
      );
    });
  }

  // Método para cambiar entre cámara frontal y trasera
  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera; // Cambia la cámara seleccionada
      _initializeCamera(); // Reinicializa la cámara con la nueva selección
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Càmera'), // Título en la barra superior
        centerTitle: true, // Centra el título en la AppBar
        actions: [
          IconButton(
            icon: Icon(_isFlashOn
                ? Icons.flash_on
                : Icons.flash_off), // Icono del flash
            onPressed:
                _toggleFlash, // Llama al método para cambiar el estado del flash
          ),
          IconButton(
            icon:
                const Icon(Icons.switch_camera), // Icono para cambiar la cámara
            onPressed: _switchCamera, // Llama al método para cambiar la cámara
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future:
            _initializeControllerFuture, // Espera la inicialización de la cámara
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Ajuste para que CameraPreview ocupe toda la pantalla
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit
                        .cover, // Ajusta la vista previa para cubrir toda la pantalla
                    child: SizedBox(
                      width: MediaQuery.of(context)
                          .size
                          .width, // Ancho de la pantalla
                      height: MediaQuery.of(context)
                          .size
                          .height, // Alto de la pantalla
                      child: CameraPreview(
                          _controller), // Muestra la vista previa de la cámara
                    ),
                  ),
                ),
                // Botón flotante para capturar imágenes
                Positioned(
                  bottom: 32,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed:
                        _takePicture, // Llama al método para capturar la imagen
                    child: const Icon(Icons.camera), // Icono de la cámara
                  ),
                ),
              ],
            );
          } else {
            return const Center(
                child:
                    CircularProgressIndicator()); // Muestra un indicador de carga si la cámara aún no está lista
          }
        },
      ),
    );
  }
}

/// Pantalla de la galería que muestra las imágenes capturadas.
class GalleryScreen extends StatelessWidget {
  final List<String> capturedImages; // Lista de rutas de imágenes capturadas.

  const GalleryScreen({super.key, required this.capturedImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture'), // Título en la barra de navegación.
        centerTitle: true, // Centra el título en la AppBar.
      ),
      body: capturedImages.isEmpty
          ? const Center(
              child: Text(
                  'No hay fotos capturadas')) // Muestra un mensaje si no hay imágenes.
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Número de columnas en la cuadrícula.
                childAspectRatio: 1, // Proporción de aspecto cuadrada.
              ),
              itemCount: capturedImages.length, // Número total de imágenes.
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(
                      4.0), // Espaciado entre las imágenes.
                  child: Image.file(
                    File(capturedImages[
                        index]), // Muestra la imagen desde el archivo.
                    fit: BoxFit
                        .cover, // Ajusta la imagen para llenar su espacio.
                  ),
                );
              },
            ),
    );
  }
}

/// Pantalla del reproductor de música.
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  MusicPlayerScreenState createState() => MusicPlayerScreenState();
}

/// Estado del reproductor de música.
class MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Instancia del reproductor de audio.

  @override
  void initState() {
    super.initState();
  }

  /// Método para reproducir el audio desde un archivo en los assets.
  Future<void> _playAudio() async {
    try {
      await _audioPlayer.setAsset(
          'assets/audio.mp3'); // Carga el archivo de audio desde los assets.
      _audioPlayer.play(); // Reproduce el audio.
    } catch (e) {
      print("Error playing audio: $e"); // Muestra un error en caso de falla.
    }
  }

  /// Método para detener el audio.
  Future<void> _stopAudio() async {
    await _audioPlayer.stop(); // Detiene la reproducción del audio.
  }

  /// Método para cambiar la velocidad de reproducción.
  Future<void> _setPlaybackRate(double rate) async {
    _audioPlayer.setSpeed(rate); // Modifica la velocidad de reproducción.
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Libera los recursos del reproductor al salir.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'), // Título de la pantalla.
        centerTitle: true, // Centra el título en la AppBar.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra los botones verticalmente.
          children: <Widget>[
            ElevatedButton(
              onPressed:
                  _playAudio, // Llama al método para reproducir el audio.
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: _stopAudio, // Llama al método para detener el audio.
              child: const Text('Stop'),
            ),
            ElevatedButton(
              onPressed: () => _setPlaybackRate(
                  1.5), // Aumenta la velocidad de reproducción.
              child: const Text('Increase Speed'),
            ),
            ElevatedButton(
              onPressed: () =>
                  _setPlaybackRate(0.5), // Reduce la velocidad de reproducción.
              child: const Text('Decrease Speed'),
            ),
          ],
        ),
      ),
    );
  }
}
