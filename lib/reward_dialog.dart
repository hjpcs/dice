import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'reward_service.dart';

class RewardDialog extends StatefulWidget {
  final RewardResult reward;
  final VoidCallback onDismiss;

  const RewardDialog({
    super.key,
    required this.reward,
    required this.onDismiss,
  });

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  // Helper to determine icon/color based on reward amount
  (IconData, Color) _getRewardStyle() {
    if (widget.reward.amount >= 5200) {
      return (Icons.diamond, Colors.purpleAccent); // Leopard
    } else if (widget.reward.amount >= 1314) {
      return (Icons.stars, Colors.redAccent); // Extreme Sum
    } else if (widget.reward.amount >= 520) {
      return (Icons.favorite, Colors.pinkAccent); // Medium Sum
    } else if (widget.reward.amount > 0) {
      return (Icons.thumb_up, Colors.orangeAccent); // Pair
    } else {
      return (Icons.sentiment_neutral, Colors.grey); // No Reward
    }
  }

  Future<void> _saveToGallery() async {
    // Gal handles permissions automatically for Android and iOS
    // We just need to make sure we handle the UI state

    setState(() {
      _isSaving = true;
    });

    try {
      final directory = (await getTemporaryDirectory()).path;
      final fileName = 'dice_reward_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Capture widget
      final imagePath = await _screenshotController.captureAndSave(
        directory,
        fileName: fileName,
        pixelRatio: 3.0,
      );

      if (imagePath != null) {
        // Save to gallery using Gal
        // Gal.putImage requires the file path
        await Gal.putImage(imagePath, album: '骰子大赛');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      // If it's a permission error, Gal might throw or we might need to handle it
      // But Gal usually requests permissions automatically.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getRewardStyle();
    final bool hasReward = widget.reward.amount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // We wrap the visual content in Screenshot
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon Header
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 64,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Dice Result Display
                    if (widget.reward.diceValues.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '投掷结果: ',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            ...widget.reward.diceValues.map((value) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '$value',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description Text
                    Text(
                      widget.reward.description,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    
                    // Amount Text (Only show if has reward)
                    if (hasReward) ...[
                      Text(
                        '获得奖金',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${widget.reward.amount.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '别气馁，下次一定中！',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  // Save Button (Only if has reward)
                  if (hasReward) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveToGallery,
                        icon: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_alt),
                        label: Text(_isSaving ? '保存中...' : '保存图片分享'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        hasReward ? '开心收下' : '再试一次',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
