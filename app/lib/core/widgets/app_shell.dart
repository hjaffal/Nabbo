import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/capture/presentation/capture_sheet.dart';
import '../../features/capture/presentation/voice_capture_sheet.dart';
import '../../features/capture/presentation/image_capture_sheet.dart';
import '../../features/capture/presentation/share_handler.dart';

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
      floatingActionButton: showFab ? const _ExpandableFab() : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'Review',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable FAB with animated speed-dial options that fan out.
class _ExpandableFab extends StatefulWidget {
  const _ExpandableFab();

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    if (_isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop overlay when open
        if (_isOpen)
          Positioned.fill(
            right: -16,
            bottom: -16,
            left: -MediaQuery.of(context).size.width,
            top: -MediaQuery.of(context).size.height,
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _controller.value,
                  child: child,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),

        // Floating options
        _buildOption(
          index: 2,
          icon: Icons.image_rounded,
          label: 'Photo',
          color: AppColors.chipGreen,
          bgColor: AppColors.greenLight,
          offset: 200,
          onTap: () {
            _close();
            showImageCaptureSheet(context);
          },
        ),
        _buildOption(
          index: 1,
          icon: Icons.mic_rounded,
          label: 'Voice',
          color: AppColors.chipOrange,
          bgColor: AppColors.orangeLight,
          offset: 136,
          onTap: () {
            _close();
            showVoiceCaptureSheet(context);
          },
        ),
        _buildOption(
          index: 0,
          icon: Icons.edit_note_rounded,
          label: 'Note',
          color: AppColors.chipPurple,
          bgColor: AppColors.lavenderLight,
          offset: 72,
          onTap: () {
            _close();
            showCaptureSheet(context);
          },
        ),

        // Main FAB
        _buildMainFab(),
      ],
    );
  }

  Widget _buildOption({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required double offset,
    required VoidCallback onTap,
  }) {
    // Stagger the animation for each option
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 0.7 + delay, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = animation.value;
        final translateY = (1 - scale) * 20;

        return Positioned(
          bottom: offset * scale,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale.clamp(0.0, 1.0),
                alignment: Alignment.bottomRight,
                child: child,
              ),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFab() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final rotation = _controller.value * 0.125; // 45 degrees = 0.125 turns
        return Transform.rotate(
          angle: rotation * 3.14159 * 2,
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: _toggle,
        elevation: _isOpen ? 8 : 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
