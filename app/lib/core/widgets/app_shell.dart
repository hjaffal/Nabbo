import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/presentation/capture_sheet.dart';
import '../../features/capture/presentation/voice_capture_sheet.dart';
import '../../features/capture/presentation/image_capture_sheet.dart';
import '../../features/capture/presentation/share_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late ShareHandler _shareHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareHandler = ShareHandler(ref: ref, context: context);
      _shareHandler.initialize();
    });
  }

  @override
  void dispose() {
    _shareHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFab = widget.navigationShell.currentIndex == 0;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: showFab ? const _AnimatedCaptureFab() : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Animated expandable FAB with speed-dial mini buttons
class _AnimatedCaptureFab extends StatefulWidget {
  const _AnimatedCaptureFab();

  @override
  State<_AnimatedCaptureFab> createState() => _AnimatedCaptureFabState();
}

class _AnimatedCaptureFabState extends State<_AnimatedCaptureFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 280,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Scrim (tap to close)
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

          // Mini FAB 3: Image (top)
          _buildMiniFab(
            index: 2,
            icon: Icons.image_rounded,
            label: 'Photo',
            color: AppColors.softGreen,
            bgColor: AppColors.greenLight,
            onTap: () {
              _close();
              showImageCaptureSheet(context);
            },
          ),

          // Mini FAB 2: Voice (middle)
          _buildMiniFab(
            index: 1,
            icon: Icons.mic_rounded,
            label: 'Voice',
            color: AppColors.softBlue,
            bgColor: AppColors.blueLight,
            onTap: () {
              _close();
              showVoiceCaptureSheet(context);
            },
          ),

          // Mini FAB 1: Text (closest)
          _buildMiniFab(
            index: 0,
            icon: Icons.edit_note_rounded,
            label: 'Text',
            color: AppColors.warmYellow,
            bgColor: AppColors.yellowLight,
            onTap: () {
              _close();
              showCaptureSheet(context);
            },
          ),

          // Main FAB
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.extended(
              heroTag: 'nabbo_fab',
              onPressed: _toggle,
              icon: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * math.pi / 4,
                    child: const Icon(Icons.add),
                  );
                },
              ),
              label: const Text('Nabbo it'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final offset = 64.0 + (index * 56.0); // spacing between mini fabs

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.15, 0.6 + index * 0.15, curve: Curves.easeOut),
        ).value;

        return Positioned(
          bottom: offset * scale,
          right: 4,
          child: Opacity(
            opacity: scale,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mini FAB button
          Material(
            color: bgColor,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: color.withValues(alpha: 0.3),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
