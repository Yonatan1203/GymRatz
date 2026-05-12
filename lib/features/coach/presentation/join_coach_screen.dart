import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';

class JoinCoachScreen extends ConsumerStatefulWidget {
  const JoinCoachScreen({super.key});

  @override
  ConsumerState<JoinCoachScreen> createState() => _JoinCoachScreenState();
}

class _JoinCoachScreenState extends ConsumerState<JoinCoachScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a 6-character invite code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw StateError('Not signed in');

      if (profile.coachId != null) {
        setState(() {
          _error = 'You are already linked to a coach';
          _isLoading = false;
        });
        return;
      }

      final coachService = ref.read(coachServiceProvider);
      final coachName = await coachService.joinCoach(
        code: code,
        clientUid: profile.uid!,
        clientName: profile.name,
        clientEmail: profile.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined coach: $coachName')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('StateError: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Join a Coach',
                  style: AppTextStyles.h1.copyWith(color: context.foreground)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-character invite code from your coach.',
                    style: AppTextStyles.body
                        .copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _controller,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    style: AppTextStyles.h2.copyWith(
                      letterSpacing: 8,
                      color: context.foreground,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'XXXXXX',
                      hintStyle: AppTextStyles.h2.copyWith(
                        letterSpacing: 8,
                        color: context.mutedForeground.withValues(alpha: 0.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(_error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.destructiveColor)),
                  ],
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: _isLoading ? 'Joining...' : 'Join Coach',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleJoin,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
