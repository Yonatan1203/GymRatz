import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientUid;
  const ClientDetailScreen({super.key, required this.clientUid});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);

    return StreamBuilder<UserProfile?>(
      stream: userRepo.watchUser(widget.clientUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final clientName = profile?.name ?? 'Client';

        return Scaffold(
          body: Column(
            children: [
              _buildHeader(context, clientName),
              TabBar(
                controller: _tabController,
                labelColor: context.primaryColor,
                unselectedLabelColor: context.mutedForeground,
                indicatorColor: context.primaryColor,
                labelStyle: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Workouts'),
                  Tab(text: 'Programs'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(
                      clientUid: widget.clientUid,
                      profile: profile,
                    ),
                    _WorkoutsTab(clientUid: widget.clientUid),
                    _ProgramsTab(clientUid: widget.clientUid),
                  ],
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String clientName) {
    return GradientHeader(
      showBackButton: true,
      child: Text(
        clientName,
        style: AppTextStyles.h2.copyWith(
          color: context.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    context.go('/coach/clients/${widget.clientUid}/assign'),
                icon: Icon(AppIcons.plus, size: 18.r),
                label: const Text('Assign Program'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  textStyle: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRemoveDialog(context),
                icon: Icon(AppIcons.trash2, size: 18.r),
                label: const Text('Remove Client'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.destructiveColor,
                  side: BorderSide(color: context.destructiveColor),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  textStyle: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Client'),
        content: const Text(
          'Are you sure you want to remove this client? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.destructiveColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final coachUid = ref.read(currentUidProvider);
      if (coachUid == null) return;
      await ref
          .read(coachServiceProvider)
          .removeClient(coachUid, widget.clientUid);
      if (mounted) context.pop();
    }
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String clientUid;
  final UserProfile? profile;

  const _OverviewTab({required this.clientUid, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachService = ref.watch(coachServiceProvider);

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _buildProfileCard(context, profile!),
        SizedBox(height: AppSpacing.xl),
        _buildActiveProgramCard(context, coachService),
        SizedBox(height: AppSpacing.xl),
        _buildStatsCard(context, profile!),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile profile) {
    final initials = profile.initials.isNotEmpty ? profile.initials : '?';
    final linkedDate = profile.coachLinkedAt != null
        ? DateFormat.yMMMd().format(profile.coachLinkedAt!)
        : 'Unknown';

    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.h3.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTextStyles.h4.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  profile.email,
                  style: AppTextStyles.caption
                      .copyWith(color: context.mutedForeground),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Linked $linkedDate',
                  style: AppTextStyles.caption
                      .copyWith(color: context.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProgramCard(
      BuildContext context, dynamic coachService) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: coachService.watchClientPrograms(clientUid),
      builder: (context, snapshot) {
        final programs = snapshot.data ?? [];
        final active = programs
            .where((p) => p['isActive'] == true)
            .toList();
        final programName =
            active.isNotEmpty ? active.first['name'] as String? : null;

        return CustomCard(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Icon(AppIcons.layers, size: 20.r, color: context.primaryColor),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Program',
                      style: AppTextStyles.caption
                          .copyWith(color: context.mutedForeground),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      programName ?? 'None assigned',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, UserProfile profile) {
    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Stats',
            style: AppTextStyles.h4.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _statTile(context, 'Experience', profile.experienceLevel),
              _statTile(context, 'Goal', profile.primaryGoal),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _statTile(
                  context, 'Weight', '${profile.weight} ${profile.unit}'),
              _statTile(context, 'Height', profile.height),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.caption.copyWith(color: context.mutedForeground),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Workouts Tab ──────────────────────────────────────────────────────────────

class _WorkoutsTab extends ConsumerWidget {
  final String clientUid;

  const _WorkoutsTab({required this.clientUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachService = ref.watch(coachServiceProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: coachService.watchClientWorkouts(clientUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data ?? [];

        if (workouts.isEmpty) {
          return EmptyStateWidget(
            icon: AppIcons.dumbbell,
            title: 'No workouts yet',
            subtitle: 'Completed workouts will appear here.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.lg,
          ),
          itemCount: workouts.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) =>
              _buildWorkoutCard(context, workouts[index]),
        );
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    final name = workout['name'] as String? ?? 'Workout';
    final status = workout['status'] as String? ?? '';
    final totalVolume = workout['totalVolume'];
    final rawDate = workout['date'];
    String dateStr = '';
    if (rawDate is Timestamp) {
      dateStr = DateFormat.yMMMd().add_jm().format(rawDate.toDate());
    } else if (rawDate is DateTime) {
      dateStr = DateFormat.yMMMd().add_jm().format(rawDate);
    } else if (rawDate is String) {
      dateStr = rawDate;
    }

    return CustomCard(
      variant: CardVariant.workout,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.r, vertical: 2.r),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? const Color(0xFF34C759).withValues(alpha: 0.12)
                        : context.mutedColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.caption.copyWith(
                      color: status == 'completed'
                          ? const Color(0xFF34C759)
                          : context.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (dateStr.isNotEmpty) ...[
                Icon(AppIcons.calendar,
                    size: 14.r, color: context.mutedForeground),
                SizedBox(width: 4.r),
                Text(
                  dateStr,
                  style: AppTextStyles.caption
                      .copyWith(color: context.mutedForeground),
                ),
              ],
              if (totalVolume != null) ...[
                SizedBox(width: AppSpacing.lg),
                Icon(AppIcons.dumbbell,
                    size: 14.r, color: context.mutedForeground),
                SizedBox(width: 4.r),
                Text(
                  '${totalVolume} vol',
                  style: AppTextStyles.caption
                      .copyWith(color: context.mutedForeground),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Programs Tab ──────────────────────────────────────────────────────────────

class _ProgramsTab extends ConsumerWidget {
  final String clientUid;

  const _ProgramsTab({required this.clientUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachService = ref.watch(coachServiceProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: coachService.watchClientPrograms(clientUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final programs = snapshot.data ?? [];

        if (programs.isEmpty) {
          return EmptyStateWidget(
            icon: AppIcons.layers,
            title: 'No programs',
            subtitle: 'Assign a program to get this client started.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.lg,
          ),
          itemCount: programs.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) =>
              _buildProgramCard(context, programs[index]),
        );
      },
    );
  }

  Widget _buildProgramCard(
      BuildContext context, Map<String, dynamic> program) {
    final name = program['name'] as String? ?? 'Program';
    final isActive = program['isActive'] == true;
    final assignedByCoach = program['assignedByCoach'] == true;

    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: isActive
                  ? context.primaryColor.withValues(alpha: 0.12)
                  : context.mutedColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Icon(
                AppIcons.layers,
                size: 20.r,
                color: isActive ? context.primaryColor : context.mutedForeground,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    if (isActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.r, vertical: 1.r),
                        margin: EdgeInsets.only(right: 8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Active',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF34C759),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (assignedByCoach)
                      Text(
                        'Assigned by coach',
                        style: AppTextStyles.caption
                            .copyWith(color: context.mutedForeground),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight,
              size: 18.r, color: context.mutedForeground),
        ],
      ),
    );
  }
}
