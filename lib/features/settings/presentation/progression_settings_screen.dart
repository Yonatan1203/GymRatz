import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';

class ProgressionSettingsScreen extends ConsumerWidget {
  const ProgressionSettingsScreen({super.key});

  static const _modes = [
    _ModeInfo(
      mode: ProgressionMode.hypertrophy,
      goal: 'Build Muscle',
      title: 'Hypertrophy',
      desc: 'Moderate load, 6–15 reps, emphasis on volume and metabolic stress.',
      repRange: '8–12',
      rir: '2',
      increment: '2.5–5 kg per session',
    ),
    _ModeInfo(
      mode: ProgressionMode.strength,
      goal: 'Get Stronger',
      title: 'Strength',
      desc: 'Heavy load, 1–6 reps, long rest periods, neural adaptation focus.',
      repRange: '3–5',
      rir: '1',
      increment: '1.25–2.5 kg per session',
    ),
    _ModeInfo(
      mode: ProgressionMode.endurance,
      goal: 'Improve Endurance',
      title: 'Endurance',
      desc: 'Light load, 15–20 reps, short rest, muscular conditioning focus.',
      repRange: '15–20',
      rir: '3',
      increment: '1–2.5 kg per session',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currentMode = profile?.defaultProgressionMode ?? ProgressionMode.hypertrophy;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Progression Settings',
                  style: AppTextStyles.h1.copyWith(color: context.foreground)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default training mode',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'New programs use this mode for all exercises by default. '
                    'You can override it per-exercise inside program creation.',
                    style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  ..._modes.map((info) => _ModeCard(
                    info: info,
                    isSelected: info.mode == currentMode,
                    onTap: () async {
                      final uid = ref.read(currentUidProvider);
                      if (uid == null) return;
                      await ref.read(userRepositoryProvider).updateUser(uid, {
                        'primaryGoal': info.goal,
                      });
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeInfo {
  final ProgressionMode mode;
  final String goal;
  final String title;
  final String desc;
  final String repRange;
  final String rir;
  final String increment;

  const _ModeInfo({
    required this.mode,
    required this.goal,
    required this.title,
    required this.desc,
    required this.repRange,
    required this.rir,
    required this.increment,
  });
}

class _ModeCard extends StatelessWidget {
  final _ModeInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: CustomCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? context.primaryColor : context.mutedForeground,
                    width: isSelected ? 6 : 2,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? context.primaryColor : context.foreground,
                        )),
                    SizedBox(height: 4.h),
                    Text(info.desc,
                        style: AppTextStyles.caption.copyWith(
                          color: context.mutedForeground,
                        )),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      children: [
                        _chip(context, 'Reps ${info.repRange}'),
                        _chip(context, 'RIR ${info.rir}'),
                        _chip(context, info.increment),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: context.mutedForeground.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(label,
        style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
  );
}
