import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/models/owner_chat_models.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_owner_service.dart';

class RestaurantOwnerChatDetailScreen extends StatefulWidget {
  const RestaurantOwnerChatDetailScreen({
    super.key,
    required this.customerUserId,
    required this.customerName,
  });

  final String customerUserId;
  final String customerName;

  @override
  State<RestaurantOwnerChatDetailScreen> createState() =>
      _RestaurantOwnerChatDetailScreenState();
}

class _RestaurantOwnerChatDetailScreenState
    extends State<RestaurantOwnerChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final RestaurantOwnerService _service = RestaurantOwnerService(
    authService: AuthService(),
  );
  final List<OwnerChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final ownerUserId = AppSession.userId;
    if (ownerUserId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final loaded = await _service.getChatMessages(
        ownerUserId: ownerUserId,
        customerUserId: widget.customerUserId,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
      });
    } catch (error) {
      if (!mounted) return;
      context.showErrorMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _send() async {
    if (_isSending) return;
    final ownerUserId = AppSession.userId;
    final message = _controller.text.trim();
    if (ownerUserId.isEmpty || message.isEmpty) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final created = await _service.sendOwnerMessage(
        ownerUserId: ownerUserId,
        customerUserId: widget.customerUserId,
        message: message,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(created);
        _controller.clear();
      });
    } catch (error) {
      if (!mounted) return;
      context.showErrorMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Scaffold(
      backgroundColor: colors.secondaryShade1,
      appBar: AppBar(
        backgroundColor: colors.white,
        title: Text(
          widget.customerName,
          style: typography.titleMedium.copyWith(color: colors.primaryTint2),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                      child: Text(
                        'Henüz mesaj yok.',
                        style: typography.bodySmall.copyWith(color: colors.gray4),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(Dimens.largePadding),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMine = msg.isRestaurant;
                        return Align(
                          alignment:
                              isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: Dimens.padding),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimens.largePadding,
                              vertical: Dimens.padding,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMine
                                      ? colors.primary.withValues(alpha: 0.16)
                                      : colors.white,
                              borderRadius: BorderRadius.circular(Dimens.corners),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(msg.message),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(msg.createdAtUtc),
                                  style: typography.labelSmall.copyWith(
                                    color: colors.gray4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: colors.white,
              padding: const EdgeInsets.all(Dimens.largePadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        filled: true,
                        fillColor: colors.secondaryShade1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.padding),
                  IconButton(
                    onPressed: _isSending ? null : _send,
                    icon: Icon(Icons.send_rounded, color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
