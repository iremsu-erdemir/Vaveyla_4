import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/gen/assets.gen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/models/order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_owner_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/bloc/restaurant_orders_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/utils/image_picker_helper.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/widgets/product_image_widget.dart';

class RestaurantOwnerOrdersScreen extends StatefulWidget {
  const RestaurantOwnerOrdersScreen({super.key});

  @override
  State<RestaurantOwnerOrdersScreen> createState() =>
      _RestaurantOwnerOrdersScreenState();
}

class _RestaurantOwnerOrdersScreenState
    extends State<RestaurantOwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final colors = context.theme.appColors;
    return AppScaffold(
      appBar: GeneralAppBar(
        title: 'Sipariş Yönetimi',
        showBackIcon: false,
        actions: [
          IconButton(
            onPressed: () => _showAddOrderSheet(context),
            icon: Icon(Icons.add_circle, color: colors.primary, size: 28),
            tooltip: 'Manuel sipariş ekle',
          ),
          const SizedBox(width: Dimens.padding),
        ],
        height: AppBar().preferredSize.height + 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: BlocBuilder<RestaurantOrdersCubit, List<RestaurantOrderModel>>(
            builder: (context, orders) {
              final pending = orders
                  .where((o) => o.status == RestaurantOrderStatus.pending)
                  .length;
              final preparing = orders
                  .where((o) => o.status == RestaurantOrderStatus.preparing)
                  .length;
              final completed = orders
                  .where((o) => o.status == RestaurantOrderStatus.completed)
                  .length;
              return TabBar(
                controller: _tabController,
                dividerColor: colors.gray,
                labelColor: colors.primary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                unselectedLabelColor: colors.black,
                indicatorColor: colors.primary,
                tabs: [
                  Tab(child: _TabWithBadge(label: 'Bekleyen', count: pending)),
                  Tab(child: _TabWithBadge(label: 'Hazırlanıyor', count: preparing)),
                  Tab(child: _TabWithBadge(label: 'Tamamlanan', count: completed)),
                ],
              );
            },
          ),
        ),
      ),
      body: BlocBuilder<RestaurantOrdersCubit, List<RestaurantOrderModel>>(
        builder: (context, orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: orders
                    .where((o) => o.status == RestaurantOrderStatus.pending)
                    .toList(),
                status: RestaurantOrderStatus.pending,
                tabController: _tabController,
              ),
              _OrdersList(
                orders: orders
                    .where((o) => o.status == RestaurantOrderStatus.preparing)
                    .toList(),
                status: RestaurantOrderStatus.preparing,
                tabController: _tabController,
              ),
              _OrdersList(
                orders: orders
                    .where((o) => o.status == RestaurantOrderStatus.completed)
                    .toList(),
                status: RestaurantOrderStatus.completed,
                tabController: _tabController,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddOrderSheet(BuildContext context) {
    final screenContext = context;
    final tabController = _tabController;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _AddOrderSheet(
          onSave: (
            items,
            total,
            imagePath,
            preparationMinutes,
            status,
            createdAt,
          ) async {
            final cubit = screenContext.read<RestaurantOrdersCubit>();
            await cubit.addOrder(
              items,
              total,
              imagePath: imagePath,
              preparationMinutes: preparationMinutes,
              status: status,
              createdAt: createdAt,
            );
            Navigator.pop(ctx);
            tabController.animateTo(
              status == RestaurantOrderStatus.pending
                  ? 0
                  : status == RestaurantOrderStatus.preparing
                  ? 1
                  : 2,
            );
            screenContext.showSuccessMessage('Sipariş eklendi');
          },
        ),
      ),
    );
  }
}

class _AddOrderSheet extends StatefulWidget {
  const _AddOrderSheet({required this.onSave});

  final Future<void> Function(
    String items,
    int total,
    String? imagePath,
    int? preparationMinutes,
    RestaurantOrderStatus status,
    DateTime createdAt,
  ) onSave;

  @override
  State<_AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<_AddOrderSheet> {
  final _itemsController = TextEditingController();
  final _totalController = TextEditingController();
  final _preparationMinutesController = TextEditingController();
  late final RestaurantOwnerService _service;
  late final String _ownerUserId;
  String? _selectedImagePath;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  RestaurantOrderStatus _selectedStatus = RestaurantOrderStatus.pending;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _ownerUserId = AppSession.userId;
    _service = RestaurantOwnerService(authService: AuthService());
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _totalController.dispose();
    _preparationMinutesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) {
      return;
    }
    final items = _itemsController.text.trim();
    final total = int.tryParse(_totalController.text.trim()) ?? 0;
    final prepText = _preparationMinutesController.text.trim();
    final prepMinutes = prepText.isEmpty ? null : int.tryParse(prepText);
    if (items.isEmpty) return;
    if (total <= 0) return;
    if (prepText.isNotEmpty && (prepMinutes == null || prepMinutes <= 0)) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        items,
        total,
        _selectedImagePath,
        prepMinutes,
        _selectedStatus,
        _selectedDateTime,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showErrorMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  DateTime get _selectedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  String get _dateLabel {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    return '$day.$month.$year';
  }

  String get _timeLabel {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _statusLabel(RestaurantOrderStatus status) {
    switch (status) {
      case RestaurantOrderStatus.pending:
        return 'Bekliyor';
      case RestaurantOrderStatus.preparing:
        return 'Hazırlanıyor';
      case RestaurantOrderStatus.completed:
        return 'Tamamlandı';
      case RestaurantOrderStatus.rejected:
        return 'Reddedildi';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final file = await pickAndSaveImage(source);
      if (file == null || !mounted) {
        return;
      }
      setState(() => _isUploadingImage = true);
      final uploaded = await _service.uploadMenuImage(
        ownerUserId: _ownerUserId,
        filePath: file.path,
        fileBytes: await file.readAsBytes(),
        fileName: file.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImagePath = uploaded;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showErrorMessage('Fotoğraf yüklenemedi: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.extraLargePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            'Manuel Sipariş Ekle',
            style: typography.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Dimens.largePadding),
          TextField(
            controller: _itemsController,
            decoration: InputDecoration(
              labelText: 'Sipariş içeriği',
              hintText: 'Örn: 2x Donut, 1x Kahve',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimens.corners),
              ),
            ),
          ),
          const SizedBox(height: Dimens.largePadding),
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImageSourcePicker,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: colors.gray.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(Dimens.corners),
                border: Border.all(color: colors.gray.withValues(alpha: 0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isUploadingImage
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedImagePath == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 18,
                          color: colors.gray4,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sipariş görseli ekle',
                          style: typography.bodyMedium.copyWith(
                            color: colors.gray4,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        buildProductImage(_selectedImagePath!, double.infinity, 100),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImagePath = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: Dimens.largePadding),
          TextField(
            controller: _totalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Toplam tutar (₺)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimens.corners),
              ),
            ),
          ),
          const SizedBox(height: Dimens.largePadding),
          TextField(
            controller: _preparationMinutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Hazırlanma süresi (dk)',
              hintText: 'Örn: 25',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimens.corners),
              ),
            ),
          ),
          const SizedBox(height: Dimens.largePadding),
          DropdownButtonFormField<RestaurantOrderStatus>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Durum',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimens.corners),
              ),
            ),
            items: RestaurantOrderStatus.values
                .map(
                  (status) => DropdownMenuItem<RestaurantOrderStatus>(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
          const SizedBox(height: Dimens.largePadding),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('Tarih: $_dateLabel'),
                ),
              ),
              const SizedBox(width: Dimens.padding),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_outlined, size: 18),
                  label: Text('Saat: $_timeLabel'),
                ),
              ),
            ],
          ),
            const SizedBox(height: Dimens.extraLargePadding),
            FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Sipariş Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.theme.appColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.status,
    required this.tabController,
  });

  final List<RestaurantOrderModel> orders;
  final RestaurantOrderStatus status;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: colors.gray4),
            const SizedBox(height: Dimens.largePadding),
            Text(
              'Henüz sipariş yok',
              style: typography.bodyLarge.copyWith(color: colors.gray4),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Dimens.largePadding),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimens.largePadding),
      itemBuilder: (context, index) {
        final order = orders[index];
        final accent = _statusColor(status);
        return Container(
          padding: const EdgeInsets.all(Dimens.largePadding),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(Dimens.corners),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.corners),
                child: order.imagePath.isNotEmpty
                    ? Image.network(
                        order.imagePath,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      )
                    : Assets.images.logo.image(
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: Dimens.largePadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.items,
                            style: typography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Dimens.padding),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimens.padding,
                            vertical: Dimens.smallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formatPrice(order.total),
                            style: typography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.padding),
                    Row(
                      children: [
                        _EtaChip(
                          status: status,
                          preparationMinutes: order.preparationMinutes,
                        ),
                        const SizedBox(width: Dimens.padding),
                        _ProgressChip(status: status),
                      ],
                    ),
                    if (status != RestaurantOrderStatus.completed) ...[
                      const SizedBox(height: Dimens.padding),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 320;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  spacing: Dimens.padding,
                                  runSpacing: Dimens.padding,
                                  children: _buildActionButtons(
                                    context,
                                    order,
                                    status,
                                    tabController,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Wrap(
                            spacing: Dimens.padding,
                            runSpacing: Dimens.padding,
                            alignment: WrapAlignment.end,
                            children: _buildActionButtons(
                              context,
                              order,
                              status,
                              tabController,
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: Dimens.padding),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.time,
                                style: typography.bodySmall.copyWith(
                                  color: colors.gray4,
                                ),
                              ),
                              if (order.date.isNotEmpty)
                                Text(
                                  order.date,
                                  style: typography.bodySmall.copyWith(
                                    color: colors.gray4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _statusText(status),
                          style: typography.labelSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  List<Widget> _buildActionButtons(
    BuildContext context,
    RestaurantOrderModel order,
    RestaurantOrderStatus status,
    TabController tabController,
  ) {
    final colors = context.theme.appColors;
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.largePadding,
        vertical: Dimens.padding,
      ),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    if (status == RestaurantOrderStatus.pending) {
      return [
        FilledButton(
          onPressed: () {
            context.read<RestaurantOrdersCubit>().acceptOrder(order.id);
            tabController.animateTo(1);
            context.showSuccessMessage('Sipariş #${order.id} kabul edildi');
          },
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(colors.success),
          ),
          child: const Text('Kabul'),
        ),
        FilledButton(
          onPressed: () {
            context.read<RestaurantOrdersCubit>().rejectOrder(order.id);
            context.showErrorMessage('Sipariş #${order.id} reddedildi');
          },
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(colors.error),
          ),
          child: const Text('Reddet'),
        ),
      ];
    }
    if (status == RestaurantOrderStatus.preparing) {
      return [
        FilledButton(
          onPressed: () {
            context.read<RestaurantOrdersCubit>().markReady(order.id);
            tabController.animateTo(2);
            context.showSuccessMessage('Sipariş #${order.id} hazır');
          },
          style: buttonStyle,
          child: const Text('Hazır'),
        ),
      ];
    }
    return [];
  }

  Color _statusColor(RestaurantOrderStatus s) {
    switch (s) {
      case RestaurantOrderStatus.pending:
        return const Color(0xFFFFA726);
      case RestaurantOrderStatus.preparing:
        return const Color(0xFF42A5F5);
      case RestaurantOrderStatus.completed:
        return const Color(0xFF66BB6A);
      case RestaurantOrderStatus.rejected:
        return const Color(0xFFEF5350);
    }
  }

  String _statusText(RestaurantOrderStatus s) {
    switch (s) {
      case RestaurantOrderStatus.pending:
        return 'Bekliyor';
      case RestaurantOrderStatus.preparing:
        return 'Hazırlanıyor';
      case RestaurantOrderStatus.completed:
        return 'Tamamlandı';
      case RestaurantOrderStatus.rejected:
        return 'Reddedildi';
    }
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.status, this.preparationMinutes});

  final RestaurantOrderStatus status;
  final int? preparationMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    final eta = preparationMinutes ?? _estimateMinutes(status);
    if (eta == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.padding,
        vertical: Dimens.smallPadding,
      ),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Tahmini $eta dk',
        style: typography.labelSmall.copyWith(
          color: colors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int? _estimateMinutes(RestaurantOrderStatus status) {
    switch (status) {
      case RestaurantOrderStatus.pending:
        return 25;
      case RestaurantOrderStatus.preparing:
        return 15;
      case RestaurantOrderStatus.completed:
      case RestaurantOrderStatus.rejected:
        return null;
    }
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.status});

  final RestaurantOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    final percent = _progressFor(status);
    if (percent == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.padding,
        vertical: Dimens.smallPadding,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Hazırlanıyor %$percent',
        style: typography.labelSmall.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int? _progressFor(RestaurantOrderStatus status) {
    switch (status) {
      case RestaurantOrderStatus.pending:
        return 20;
      case RestaurantOrderStatus.preparing:
        return 70;
      case RestaurantOrderStatus.completed:
      case RestaurantOrderStatus.rejected:
        return null;
    }
  }
}
