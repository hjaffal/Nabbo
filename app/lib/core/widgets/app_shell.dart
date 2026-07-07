import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/presentation/capture_sheet.dart';
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

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  ShareHandler? _shareHandler;
  late AnimationController _fabController;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shareHandler = ShareHandler(ref: ref, context: context);
        _shareHandler!.initialize();
      });
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _shareHandler?.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      if (_fabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() {
        _fabOpen = false;
        _fabController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.navigationShell,

          // Scrim when FAB is open
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),

          // FAB options
          if (_fabOpen) ...[
            Positioned(
              bottom: 140 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: _FabOption(
                animation: _fabController,
                index: 1,
                icon: Icons.image_outlined,
                label: 'Photo',
                onTap: () {
                  _closeFab();
                  showImageCaptureSheet(context);
                },
              ),
            ),
            Positioned(
              bottom: 90 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: _FabOption(
                animation: _fabController,
                index: 0,
                icon: Icons.edit_note_rounded,
                label: 'Text',
                onTap: () {
                  _closeFab();
                  showCaptureSheet(context);
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Feed
                _NavItem(
                  icon: Icons.dynamic_feed_outlined,
                  selectedIcon: Icons.dynamic_feed,
                  label: 'Feed',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () {
                    _closeFab();
                    widget.navigationShell.goBranch(0,
                        initialLocation:
                            widget.navigationShell.currentIndex == 0);
                  },
                ),

                // Center FAB
                GestureDetector(
                  onTap: _toggleFab,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedBuilder(
                      animation: _fabController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _fabController.value * math.pi / 4,
                          child: const Icon(Icons.add,
                              size: 26, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),

                // Settings
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () {
                    _closeFab();
                    widget.navigationShell.goBranch(2,
                        initialLocation:
                            widget.navigationShell.currentIndex == 2);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single FAB option that animates in
class _FabOption extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabOption({
    required this.animation,
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: animation,
          curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeOut),
        ).value;

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
