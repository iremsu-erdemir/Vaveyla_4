import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/restaurant_chat_message_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/restaurant_chat_service.dart';

class RestaurantChatScreen extends StatefulWidget {
  const RestaurantChatScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String restaurantId;
  final String restaurantName;

  @override
  State<RestaurantChatScreen> createState() => _RestaurantChatScreenState();
}

class _RestaurantChatScreenState extends State<RestaurantChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final RestaurantChatService _chatService = RestaurantChatService();
  final List<RestaurantChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final customerUserId = AppSession.userId;
    if (customerUserId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final loaded = await _chatService.getMessages(
        customerUserId: customerUserId,
        restaurantId: widget.restaurantId,
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

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    final customerUserId = AppSession.userId;
    if (customerUserId.isEmpty) {
      context.showErrorMessage('Mesaj göndermek için giriş yapmalısınız.');
      return;
    }

    setState(() => _isSending = true);
    try {
      final created = await _chatService.sendMessage(
        customerUserId: customerUserId,
        restaurantId: widget.restaurantId,
        message: message,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(created);
        _messageController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      context.showErrorMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurantName,
              style: typography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primaryTint2,
              ),
            ),
            Text(
              'Çevrimiçi',
              style: typography.bodySmall.copyWith(color: colors.gray4),
            ),
          ],
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
                        'Henüz mesaj yok. İlk mesajı siz gönderin.',
                        style: typography.bodySmall.copyWith(color: colors.gray4),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(Dimens.largePadding),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMine =
                            message.senderType.toLowerCase() == 'customer' &&
                            message.senderUserId == AppSession.userId;
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
                                Text(
                                  message.message,
                                  style: typography.bodySmall.copyWith(
                                    color: colors.primaryTint2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.createdAtUtc),
                                  style: typography.bodySmall.copyWith(
                                    color: colors.gray4,
                                    fontSize: 11,
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
              padding: const EdgeInsets.fromLTRB(
                Dimens.largePadding,
                Dimens.padding,
                Dimens.largePadding,
                Dimens.largePadding,
              ),
              decoration: BoxDecoration(
                color: colors.white,
                boxShadow: [
                  BoxShadow(
                    color: colors.gray.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        filled: true,
                        fillColor: colors.secondaryShade1,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimens.largePadding,
                          vertical: Dimens.padding,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.padding),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: Icon(Icons.send_rounded, color: colors.white),
                    ),
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
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
