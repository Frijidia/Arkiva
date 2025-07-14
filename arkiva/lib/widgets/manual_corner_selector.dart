import 'dart:io';
import 'package:flutter/material.dart';

class ManualCornerSelector extends StatefulWidget {
  final File imageFile;
  final void Function(List<Offset> corners) onValidate;

  const ManualCornerSelector({
    Key? key,
    required this.imageFile,
    required this.onValidate,
  }) : super(key: key);

  @override
  State<ManualCornerSelector> createState() => _ManualCornerSelectorState();
}

class _ManualCornerSelectorState extends State<ManualCornerSelector> {
  late List<Offset> _corners;
  final double _pointSize = 24;

  @override
  void initState() {
    super.initState();
    // Coins initiaux : bords de l'image
    _corners = [
      const Offset(40, 40),
      const Offset(260, 40),
      const Offset(260, 360),
      const Offset(40, 360),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuster les coins'),
        actions: [
          TextButton(
            onPressed: () => widget.onValidate(_corners),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth * 0.9;
            final double maxHeight = constraints.maxHeight * 0.7;
            return Stack(
              children: [
                // Image
                Center(
                  child: Image.file(
                    widget.imageFile,
                    width: maxWidth,
                    height: maxHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                // Points drag & drop
                ...List.generate(4, (i) {
                  return _buildDraggablePoint(i, maxWidth, maxHeight);
                }),
                // Polygone
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PolygonPainter(_corners, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraggablePoint(int i, double maxWidth, double maxHeight) {
    final Offset pt = _corners[i];
    return Positioned(
      left: pt.dx,
      top: pt.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newX = (pt.dx + details.delta.dx).clamp(0, maxWidth - _pointSize);
            double newY = (pt.dy + details.delta.dy).clamp(0, maxHeight - _pointSize);
            _corners[i] = Offset(newX, newY);
          });
        },
        child: Container(
          width: _pointSize,
          height: _pointSize,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _PolygonPainter(this.points, {this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 4) return;
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 