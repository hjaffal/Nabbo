import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      body: householdAsync.when(
        data: (household) {
          if (household == null) return const _EmptyState();
          return _TodayContent(householdId: household.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _TodayContent extends StatefulWidget {
  final String householdId;
  const _TodayContent({required this.householdId});

  @override
  State<_TodayContent> createState() => _TodayContentState();
}

class _TodayContentState extends State<_TodayContent> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final householdRef = db.collection('households').doc(widget.householdId);

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return CustomScrollView(
      slivers: [
        // App bar area with greeting
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What needs attention?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),

        // Date selector card (tappable)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: GestureDetector(
              onTap: _pickDate,
              child: _StatusCard(selectedDate: _selectedDate),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Events section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _EventsSection(householdRef: householdRef),
          ),
        ),

        // Tasks section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _TasksSection(householdRef: householdRef),
          ),
        ),

        // Required items section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _RequiredItemsSection(householdRef: householdRef),
          ),
        ),

        // Payments section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _PaymentsSection(householdRef: householdRef),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StatusCard extends StatelessWidget {
  final DateTime selectedDate;
  const _StatusCard({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    return SoftCard(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : _dayLabel(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateString(),
                  style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }

  String _dayLabel() {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday[selectedDate.weekday - 1];
  }

  String _dateString() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${selectedDate.day} ${months[selectedDate.month - 1]} ${selectedDate.year}';
  }
}

// --- Events Section ---
class _EventsSection extends StatelessWidget {
  final DocumentReference householdRef;

  const _EventsSection({required this.householdRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: householdRef.collection('events')
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Events'),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final time = (d['startDateTime'] as Timestamp?)?.toDate();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ActionCard(
                  icon: Icons.event_rounded,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.lavenderLight,
                  title: d['title'] ?? 'Event',
                  subtitle: '${d['affectedMemberName'] ?? ''}${time != null ? ' · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : ''}${d['location'] != null ? ' · ${d['location']}' : ''}',
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

// --- Tasks Section ---
class _TasksSection extends StatelessWidget {
  final DocumentReference householdRef;
  const _TasksSection({required this.householdRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: householdRef.collection('tasks')
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Tasks'),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ActionCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.warmYellow,
                  iconBackground: AppColors.yellowLight,
                  title: d['title'] ?? 'Task',
                  subtitle: d['affectedMemberName'] != null
                      ? '${d['affectedMemberName']}${d['ownerName'] != null ? ' · Owner: ${d['ownerName']}' : ' · Owner missing'}'
                      : d['ownerName'] != null ? 'Owner: ${d['ownerName']}' : 'Owner missing',
                  actionLabel: 'Done',
                  onAction: () async {
                    await householdRef.collection('tasks').doc(doc.id).update({'status': 'completed'});
                  },
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

// --- Required Items Section ---
class _RequiredItemsSection extends StatelessWidget {
  final DocumentReference householdRef;
  const _RequiredItemsSection({required this.householdRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: householdRef.collection('requiredItems')
          .where('packedStatus', isEqualTo: 'notReady')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Things to bring'),
            SoftCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await householdRef.collection('requiredItems').doc(doc.id).update({'packedStatus': 'ready'});
                          },
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(d['name'] ?? 'Item', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        if (d['affectedMemberName'] != null)
                          CategoryChip(label: d['affectedMemberName'], color: AppColors.primary),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

// --- Payments Section ---
class _PaymentsSection extends StatelessWidget {
  final DocumentReference householdRef;
  const _PaymentsSection({required this.householdRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: householdRef.collection('payments')
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Payments'),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final amount = d['amount'];
              final currency = d['currency'] ?? 'EUR';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ActionCard(
                  icon: Icons.payment_rounded,
                  iconColor: AppColors.softBlue,
                  iconBackground: AppColors.blueLight,
                  title: d['title'] ?? 'Payment',
                  subtitle: '${amount != null ? '$currency $amount' : ''}${d['affectedMemberName'] != null ? ' · ${d['affectedMemberName']}' : ''}',
                  actionLabel: 'Paid',
                  onAction: () async {
                    await householdRef.collection('payments').doc(doc.id).update({'status': 'paid'});
                  },
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: AppColors.softGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing needs attention today.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nabbo a message when something comes in.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
