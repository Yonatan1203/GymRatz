import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _sections = [
    _FaqSection(title: 'Getting Started', items: [
      _FaqItem(
        question: 'How do I create a workout program?',
        answer:
            'Go to the Programs tab, tap "Create New Program", give it a name, and add workout days. For each day, assign exercises with sets, rep ranges, and progression settings.',
      ),
      _FaqItem(
        question: 'What is a "Main Program"?',
        answer:
            'Your Main Program is the one that shows on your Workout tab and Calendar. It determines your weekly schedule. You can change your Main Program anytime from the Programs tab by tapping "Set as Main" on any program.',
      ),
      _FaqItem(
        question: 'How do I start a workout?',
        answer:
            'Go to the Workout tab and tap on today\'s scheduled workout. You\'ll see your exercises pre-loaded with weights from your last session (if you chose to restore weights).',
      ),
    ]),
    _FaqSection(title: 'Subscription', items: [
      _FaqItem(
        question: 'Is there a free trial?',
        answer:
            'Yes! Every new subscriber gets a 7-day free trial. You can cancel anytime during the trial and won\'t be charged.',
      ),
      _FaqItem(
        question: 'What happens when my subscription expires?',
        answer:
            'You can still view your data, but you won\'t be able to log workouts or make changes until you resubscribe.',
      ),
      _FaqItem(
        question: 'How do I cancel my subscription?',
        answer:
            'Subscriptions are managed through Apple App Store or Google Play Store. Go to your device\'s subscription settings to cancel or change your plan.',
      ),
      _FaqItem(
        question: 'Can I switch between monthly and yearly?',
        answer:
            'Yes. Cancel your current plan and subscribe to the other one. Your access continues until the current billing period ends.',
      ),
    ]),
    _FaqSection(title: 'Workouts & Progression', items: [
      _FaqItem(
        question: 'How does progressive overload work?',
        answer:
            'GymRatz tracks your weights and reps each session. After completing a workout, the progression engine suggests when to increase weight based on your rep range, RIR (Reps In Reserve), and progression mode.',
      ),
      _FaqItem(
        question: 'What do the workout statuses mean?',
        answer:
            'Scheduled — upcoming workout day. Done — completed this week. Missed — past day without a logged workout. Today — your workout for today.',
      ),
      _FaqItem(
        question: 'Can I do a workout on a different day?',
        answer:
            'Yes. Tap any scheduled day in the Workout tab. You\'ll see a confirmation that the workout is from a different day, then you can start it.',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Help & FAQ',
                style: AppTextStyles.h1.copyWith(color: context.foreground),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  ..._sections.map((section) => _buildSection(context, section)),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildContactCard(context),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _FaqSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.sectionGap),
        Text(
          section.title,
          style: AppTextStyles.h3.copyWith(
            color: context.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        ...section.items.map((item) => _buildFaqTile(context, item)),
      ],
    );
  }

  Widget _buildFaqTile(BuildContext context, _FaqItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: context.borderColor),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: context.borderColor),
          ),
          backgroundColor: context.cardColor,
          collapsedBackgroundColor: context.cardColor,
          title: Text(
            item.question,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.mutedForeground,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(AppIcons.mail, size: 24.r, color: context.primaryColor),
          SizedBox(height: AppSpacing.md),
          Text(
            'Still have questions?',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'support@gymratz-app.com',
            style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _FaqSection {
  final String title;
  final List<_FaqItem> items;
  const _FaqSection({required this.title, required this.items});
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
