import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/models/owner_chat_models.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_owner_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_chat_detail_screen.dart';

class RestaurantOwnerChatsScreen extends StatefulWidget {
  const RestaurantOwnerChatsScreen({super.key});

  @override
  State<RestaurantOwnerChatsScreen> createState() =>
      _RestaurantOwnerChatsScreenState();
}

class _RestaurantOwnerChatsScreenState extends State<RestaurantOwnerChatsScreen> {
  final RestaurantOwnerService _service = RestaurantOwnerService(
    authService: AuthService(),
  );
  bool _isLoading = true;
  List<OwnerChatConversationModel> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ownerUserId = AppSession.userId;
    if (ownerUserId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _service.getChatConversations(ownerUserId: ownerUserId);
      if (!mounted) return;
      setState(() => _conversations = data);
    } catch (error) {
      if (!mounted) return;
      context.showErrorMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.appTypography;
    final colors = context.theme.appColors;
    return AppScaffold(
      appBar: const GeneralAppBar(title: 'Sohbetler'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? Center(
                child: Text(
                  'Henüz müşteri mesajı yok.',
                  style: typography.bodySmall.copyWith(color: colors.gray4),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(Dimens.largePadding),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Dimens.padding),
                  itemBuilder: (context, index) {
                    final item = _conversations[index];
                    return ListTile(
                      tileColor: colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.corners),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.16),
                        child: Icon(Icons.person, color: colors.primary),
                      ),
                      title: Text(
                        item.customerName,
                        style: typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        item.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(item.lastMessageAtUtc),
                        style: typography.labelSmall.copyWith(color: colors.gray4),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => RestaurantOwnerChatDetailScreen(
                                  customerUserId: item.customerUserId,
                                  customerName: item.customerName,
                                ),
                          ),
                        );
                        if (mounted) {
                          _load();
                        }
                      },
                    );
                  },
                ),
              ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
