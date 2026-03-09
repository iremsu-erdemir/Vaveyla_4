import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/modern_order_card.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/customer_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/customer_review_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/customer_review_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/customer_orders_cubit.dart';

import '../../../../core/theme/dimens.dart';

enum OrderType { active, completed, canceled }

class OrdersListWidget extends StatelessWidget {
  const OrdersListWidget({super.key, required this.orderType});

  final OrderType orderType;

  @override
  Widget build(BuildContext context) {
    final appColors = context.theme.appColors;
    return BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredOrders = state.orders
            .where((order) => _matchesTab(order.status, orderType))
            .toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Text(
              'Sipariş bulunamadı',
              style: context.theme.appTypography.bodyMedium.copyWith(
                color: appColors.gray4,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<CustomerOrdersCubit>().loadOrders(),
          child: ListView.separated(
            itemCount: filteredOrders.length,
            itemBuilder: (final context, final index) {
              final order = filteredOrders[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.largePadding,
                ),
                child: ModernOrderCard(
                  productName: order.items,
                  price: order.total,
                  imageUrl: order.imagePath,
                  quantity: 1,
                  dateTime: '${order.date} • ${order.time}',
                  status: _statusText(order.status),
                  statusColor: _statusColor(order.status, appColors),
                  actionButton: _buildActionButton(
                    context,
                    order,
                    appColors,
                  ),
                  onTap: () {},
                ),
              );
            },
            separatorBuilder: (final context, final index) {
              return const SizedBox(height: Dimens.largePadding);
            },
          ),
        );
      },
    );
  }

  bool _matchesTab(CustomerOrderStatus status, OrderType tab) {
    switch (tab) {
      case OrderType.active:
        return status == CustomerOrderStatus.pending ||
            status == CustomerOrderStatus.preparing ||
            status == CustomerOrderStatus.assigned ||
            status == CustomerOrderStatus.inTransit;
      case OrderType.completed:
        return status == CustomerOrderStatus.completed;
      case OrderType.canceled:
        return status == CustomerOrderStatus.canceled;
    }
  }

  String _statusText(CustomerOrderStatus status) {
    switch (status) {
      case CustomerOrderStatus.pending:
        return 'Bekliyor';
      case CustomerOrderStatus.preparing:
        return 'Hazırlanıyor';
      case CustomerOrderStatus.assigned:
        return 'Kurye atandı';
      case CustomerOrderStatus.inTransit:
        return 'Yolda';
      case CustomerOrderStatus.completed:
        return 'Tamamlandı';
      case CustomerOrderStatus.canceled:
        return 'İptal edildi';
    }
  }

  Color _statusColor(CustomerOrderStatus status, dynamic appColors) {
    switch (status) {
      case CustomerOrderStatus.pending:
      case CustomerOrderStatus.preparing:
      case CustomerOrderStatus.assigned:
      case CustomerOrderStatus.inTransit:
        return appColors.primary;
      case CustomerOrderStatus.completed:
        return appColors.success;
      case CustomerOrderStatus.canceled:
        return appColors.error;
    }
  }

  Widget? _buildActionButton(
    BuildContext context,
    CustomerOrderModel order,
    dynamic appColors,
  ) {
    final status = order.status;
    return SizedBox(
      width: 96,
      height: 32,
      child: AppButton(
        title: status == CustomerOrderStatus.completed
            ? 'Yorumla'
            : status == CustomerOrderStatus.canceled
            ? 'İptal'
            : 'Takip et',
        color: status == CustomerOrderStatus.completed
            ? appColors.successLight
            : status == CustomerOrderStatus.canceled
            ? appColors.error
            : appColors.primary,
        textStyle: context.theme.appTypography.labelMedium.copyWith(
          color: status == CustomerOrderStatus.completed
              ? appColors.success
              : appColors.white,
          fontWeight: FontWeight.w600,
        ),
        borderRadius: 12,
        margin: EdgeInsets.zero,
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: Dimens.padding),
        ),
        onPressed: status == CustomerOrderStatus.completed
            ? () => _showOrderReviewSheet(context, order)
            : () {},
      ),
    );
  }

  Future<void> _showOrderReviewSheet(
    BuildContext context,
    CustomerOrderModel order,
  ) async {
    final reviewService = CustomerReviewService();
    final userId = AppSession.userId;
    if (userId.isEmpty || order.restaurantId.isEmpty) {
      if (!context.mounted) return;
      context.showErrorMessage('Değerlendirme için sipariş bilgisi eksik.');
      return;
    }

    final commentController = TextEditingController();
    var rating = 5;
    var existingReviews = <CustomerReviewModel>[];
    try {
      final loaded = await reviewService.getReviews(
        targetType: 'order',
        targetId: order.id,
        restaurantId: order.restaurantId,
        page: 1,
        pageSize: 5,
      );
      existingReviews = loaded.items;
    } catch (_) {}

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: Dimens.largePadding,
            right: Dimens.largePadding,
            top: Dimens.largePadding,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + Dimens.largePadding,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş Değerlendir',
                    style: context.theme.appTypography.titleMedium,
                  ),
                  const SizedBox(height: Dimens.padding),
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setSheetState(() => rating = star),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Yorumunuzu yazın',
                    ),
                  ),
                  if (existingReviews.isNotEmpty) ...[
                    const SizedBox(height: Dimens.padding),
                    Text(
                      'Mevcut Yorumlar',
                      style: context.theme.appTypography.titleSmall,
                    ),
                    const SizedBox(height: Dimens.smallPadding),
                    ...existingReviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Dimens.smallPadding),
                        child: Text(
                          '${review.customerName}: ${review.comment}',
                          style: context.theme.appTypography.bodySmall,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: Dimens.padding),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      title: 'Gönder',
                      margin: EdgeInsets.zero,
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) return;
                        try {
                          await reviewService.createReview(
                            customerUserId: userId,
                            restaurantId: order.restaurantId,
                            targetType: 'order',
                            targetId: order.id,
                            rating: rating,
                            comment: comment,
                            customerName: AppSession.fullName,
                          );
                          if (!context.mounted) return;
                          Navigator.of(sheetContext).pop();
                          context.showSuccessMessage(
                            'Sipariş yorumunuz kaydedildi.',
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          context.showErrorMessage(error);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
