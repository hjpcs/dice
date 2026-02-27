import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vector;

class Dice3D extends StatelessWidget {
  final double size;
  final Animation<double> animation;
  final int targetValue;
  final double initialRotationX;
  final double initialRotationY;

  const Dice3D({
    super.key,
    required this.size,
    required this.animation,
    required this.targetValue,
    this.initialRotationX = 0,
    this.initialRotationY = 0,
  });

  (double, double) _getTargetRotation(int value) {
    switch (value) {
      case 1:
        return (0.0, 0.0);
      case 2:
        return (0.0, -pi / 2);
      case 3:
        return (-pi / 2, 0.0);
      case 4:
        return (pi / 2, 0.0);
      case 5:
        return (0.0, pi / 2);
      case 6:
        return (0.0, pi);
      default:
        return (0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (targetX, targetY) = _getTargetRotation(targetValue);
    
    final double endRotationX = targetX + (4 * 2 * pi); 
    final double endRotationY = targetY + (3 * 2 * pi); 

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double currentX =
            initialRotationX + (endRotationX - initialRotationX) * animation.value;
        final double currentY =
            initialRotationY + (endRotationY - initialRotationY) * animation.value;
        
        final double currentZ = animation.value * 2 * pi;

        double bounce = 0;
        if (animation.value < 0.5) {
          bounce = -100 * sin(animation.value * 2 * pi);
        } else {
          bounce = -30 * sin((animation.value - 0.5) * 2 * pi) * (1 - animation.value); 
        }

        // Construct the parent rotation matrix
        final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..translate(0.0, bounce, 0.0)
            ..rotateX(currentX)
            ..rotateY(currentY)
            ..rotateZ(currentZ);

        // Define faces with their initial centers and transforms
        final faces = [
          _FaceDef(id: 1, center: vector.Vector3(0, 0, size / 2), transform: Matrix4.identity()..translate(0.0, 0.0, size / 2)),
          _FaceDef(id: 2, center: vector.Vector3(size / 2, 0, 0), transform: Matrix4.identity()..translate(size / 2, 0.0, 0.0)..rotateY(pi / 2)),
          _FaceDef(id: 3, center: vector.Vector3(0, -size / 2, 0), transform: Matrix4.identity()..translate(0.0, -size / 2, 0.0)..rotateX(pi / 2)),
          _FaceDef(id: 4, center: vector.Vector3(0, size / 2, 0), transform: Matrix4.identity()..translate(0.0, size / 2, 0.0)..rotateX(-pi / 2)),
          _FaceDef(id: 5, center: vector.Vector3(-size / 2, 0, 0), transform: Matrix4.identity()..translate(-size / 2, 0.0, 0.0)..rotateY(-pi / 2)),
          _FaceDef(id: 6, center: vector.Vector3(0, 0, -size / 2), transform: Matrix4.identity()..translate(0.0, 0.0, -size / 2)..rotateY(pi)),
        ];

        // Sort faces by transformed Z coordinate (Painter's Algorithm)
        // We want to draw the furthest faces first (lowest Z in camera space? Or highest?)
        // In standard Flutter coordinate system:
        // +Z is towards the viewer.
        // So we should draw smallest Z first (furthest away), and largest Z last (closest).
        // Let's verify: Perspective projection divides by Z. Objects at -Z are behind?
        // Flutter's camera is usually at positive Z looking at origin?
        // Actually, setEntry(3, 2, 0.001) implies a perspective division factor.
        // If Z increases, w increases, scale decreases. So +Z is away from camera?
        // Wait, 0.001 is -1/d.
        // Let's stick to simple logic: Rotate the center point.
        // If rotated Z is larger, is it closer or further?
        // Standard GL: -Z is into screen.
        // Flutter: +Z is towards viewer (stacking context).
        // Let's assume +Z is closer. So we sort ascending (smallest Z first).
        
        faces.sort((a, b) {
           final zA = _transformZ(matrix, a.center);
           final zB = _transformZ(matrix, b.center);
           return zA.compareTo(zB);
        });

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Stack(
            children: faces.map((f) => Transform(
              transform: f.transform,
              alignment: Alignment.center,
              child: _buildFace(f.id),
            )).toList(),
          ),
        );
      },
    );
  }

  double _transformZ(Matrix4 matrix, vector.Vector3 point) {
    // We only care about the Z component after transformation
    // v' = M * v
    final v = vector.Vector3.copy(point);
    // Apply matrix to vector.
    // Note: Matrix4 in Flutter multiplies column-major.
    // transform3 applies the rotation/translation/scale part.
    final result = matrix.transformed3(v);
    return result.z;
  }

  Widget _buildFace(int value) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: _buildDots(value),
      ),
    );
  }

  Widget _buildDots(int value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double dotSize = size / 5;
        final double gap = size / 5;

        List<Widget> dots = [];

        switch (value) {
          case 1:
            dots.add(Center(child: _dot(dotSize)));
            break;
          case 2:
            dots.add(Positioned(top: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, right: gap, child: _dot(dotSize)));
            break;
          case 3:
            dots.add(Positioned(top: gap, left: gap, child: _dot(dotSize)));
            dots.add(Center(child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, right: gap, child: _dot(dotSize)));
            break;
          case 4:
            dots.add(Positioned(top: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(top: gap, right: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, right: gap, child: _dot(dotSize)));
            break;
          case 5:
            dots.add(Positioned(top: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(top: gap, right: gap, child: _dot(dotSize)));
            dots.add(Center(child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, right: gap, child: _dot(dotSize)));
            break;
          case 6:
            dots.add(Positioned(top: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(top: gap, right: gap, child: _dot(dotSize)));
            dots.add(Positioned(top: size / 2 - dotSize / 2, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(top: size / 2 - dotSize / 2, right: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, left: gap, child: _dot(dotSize)));
            dots.add(Positioned(bottom: gap, right: gap, child: _dot(dotSize)));
            break;
        }

        return Stack(children: dots);
      },
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FaceDef {
  final int id;
  final vector.Vector3 center;
  final Matrix4 transform;

  _FaceDef({required this.id, required this.center, required this.transform});
}
