import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../shared/models/coach_client.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _searchQuery = '';

  List<CoachClient> _filterClients(List<CoachClient> clients) {
    if (_searchQuery.isEmpty) return clients;
    final query = _searchQuery.toLowerCase();
    return clients
        .where((c) => c.clientName.toLowerCase().contains(query))
        .toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool _isActive(CoachClient client) {
    return DateTime.now().difference(client.linkedAt).inDays < 3;
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(coachClientsProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filtered = _filterClients(clients);
                if (clients.isEmpty) {
                  return EmptyStateWidget(
                    icon: AppIcons.users,
                    title: 'No clients yet',
                    subtitle:
                        'Invite clients to get started coaching and managing their workouts.',
                    actionLabel: 'Invite Client',
                    onAction: () => context.go('/coach/invites'),
                  );
                }
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: AppIcons.search,
                    title: 'No matches',
                    subtitle:
                        'No clients match your search. Try a different name.',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.lg,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _buildClientCard(context, filtered[index]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Something went wrong.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.mutedForeground)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/coach/invites'),
        backgroundColor: context.primaryColor,
        child: Icon(AppIcons.plus, color: Colors.white, size: 24.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clients',
            style: AppTextStyles.h2.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
        decoration: InputDecoration(
          hintText: 'Search clients...',
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
          prefixIcon: Icon(AppIcons.search,
              size: 18.r, color: context.mutedForeground),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10.h),
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, CoachClient client) {
    final active = _isActive(client);

    return CustomCard(
      onTap: () => context.go('/coach/clients/${client.clientUid}'),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Avatar circle with initials
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(client.clientName),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          // Name, email, linked date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.clientName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  client.clientEmail,
                  style: AppTextStyles.caption.copyWith(
                    color: context.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Linked ${DateFormat.yMMMd().format(client.linkedAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: context.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Status indicator
          Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? const Color(0xFF34C759)
                  : context.mutedForeground.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Icon(AppIcons.chevronRight,
              size: 18.r, color: context.mutedForeground),
        ],
      ),
    );
  }
}
