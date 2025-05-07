import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SecondaryRendererWidget extends StatefulWidget {
  final bool secondaryStreamAvailable;
  final RTCVideoRenderer? secondaryRenderer;
  final bool isLocalMain;
  final VoidCallback onSwitchRenderers;

  const SecondaryRendererWidget({
    super.key,
    required this.secondaryStreamAvailable,
    required this.secondaryRenderer,
    required this.isLocalMain,
    required this.onSwitchRenderers,
  });

  @override
  State<SecondaryRendererWidget> createState() => _SecondaryRendererWidgetState();
}

class _SecondaryRendererWidgetState extends State<SecondaryRendererWidget> {
  // Constants for size and margin
  static const double _width = 200;
  static const double _height = 200;
  static const double _margin = 16;
  static const double _velocityThreshold = 800; // px/s mínimo para considerar “fling”

  /// Durante el drag acumula delta; al soltar se reinicia a Offset.zero
  Offset _dragOffset = Offset.zero;

  /// Controla si estamos en lado izquierdo/derecho y arriba/abajo
  bool _isLeft = false;
  bool _isTop = false;

  @override
  void initState() {
    super.initState();
    // Empieza en bottom-right (_isLeft=false, _isTop=false)
    _isLeft = false;
    _isTop = false;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    // Calcula la posición “base” según la esquina activa
    final baseLeft = _isLeft ? _margin : screen.width - _width - _margin;
    final baseTop = _isTop ? _margin : screen.height - _height - _margin;

    return AnimatedPositioned(
      // Durante el drag se suma el offset; cuando _dragOffset vuelve a cero,
      // AnimatedPositioned anima de la posición anterior a la nueva esquina.
      left: baseLeft + _dragOffset.dx,
      top:  baseTop  + _dragOffset.dy,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _dragOffset += details.delta);
        },
        onPanEnd: (details) {
          final vel = details.velocity.pixelsPerSecond;

          // Centro actual del widget
          final centerX = baseLeft + _dragOffset.dx + (_width  / 2);
          final centerY = baseTop  + _dragOffset.dy + (_height / 2);

          // Decide eje X: si fue un fling horizontal fuerte, usa la dirección del fling,
          // si no, usa posición final respecto al centro de pantalla
          final useFlingX = vel.dx.abs() > _velocityThreshold;
          final targetLeft = useFlingX
              ? (vel.dx < 0) // si vel.dx < 0 => izquierda
              : (centerX < screen.width / 2);

          // Mismo para Y
          final useFlingY = vel.dy.abs() > _velocityThreshold;
          final targetTop = useFlingY
              ? (vel.dy < 0) // si vel.dy < 0 => arriba
              : (centerY < screen.height / 2);

          setState(() {
            _isLeft = targetLeft;
            _isTop  = targetTop;
            _dragOffset = Offset.zero;
          });
        },
        onTap: widget.onSwitchRenderers,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey,
          ),
          child: widget.secondaryStreamAvailable
              ? RTCVideoView(widget.secondaryRenderer!, mirror: !widget.isLocalMain)
              : const Icon(Icons.person, color: Colors.white, size: 60),
        ),
      ),
    );
  }
}
