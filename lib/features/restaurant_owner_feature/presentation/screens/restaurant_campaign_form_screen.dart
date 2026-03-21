import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_campaign_service.dart';

class RestaurantCampaignFormScreen extends StatefulWidget {
  const RestaurantCampaignFormScreen({super.key});

  @override
  State<RestaurantCampaignFormScreen> createState() =>
      _RestaurantCampaignFormScreenState();
}

class _RestaurantCampaignFormScreenState
    extends State<RestaurantCampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _minCartController = TextEditingController();
  final _categoryController = TextEditingController();
  int _discountType = 1;
  int _targetType = 1;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _minCartController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await RestaurantCampaignService().createCampaign({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'discountType': _discountType,
        'discountValue': double.tryParse(_valueController.text) ?? 0,
        'targetType': _targetType,
        'targetId': null,
        'targetCategoryName': _targetType == 2
            ? (_categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim())
            : null,
        'minCartAmount': _targetType == 3
            ? (double.tryParse(_minCartController.text))
            : null,
        'discountOwner': 1,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GeneralAppBar(title: 'Yeni Kampanya'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dimens.largePadding),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kampanya Adı',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: Dimens.largePadding),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Dimens.largePadding),
            DropdownButtonFormField<int>(
              value: _discountType,
              decoration: const InputDecoration(
                labelText: 'İndirim Tipi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Yüzde (%)')),
                DropdownMenuItem(value: 2, child: Text('Sabit (₺)')),
              ],
              onChanged: (v) => setState(() => _discountType = v ?? 1),
            ),
            const SizedBox(height: Dimens.largePadding),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: _discountType == 1 ? 'İndirim %' : 'İndirim (₺)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return n == null || n <= 0 ? 'Geçerli değer girin' : null;
              },
            ),
            const SizedBox(height: Dimens.largePadding),
            DropdownButtonFormField<int>(
              value: _targetType,
              decoration: const InputDecoration(
                labelText: 'Hedef',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Ürün')),
                DropdownMenuItem(value: 2, child: Text('Kategori')),
                DropdownMenuItem(value: 3, child: Text('Sepet')),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 1),
            ),
            if (_targetType == 2) ...[
              const SizedBox(height: Dimens.largePadding),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_targetType == 3) ...[
              const SizedBox(height: Dimens.largePadding),
              TextFormField(
                controller: _minCartController,
                decoration: const InputDecoration(
                  labelText: 'Min. Sepet Tutarı (₺)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: Dimens.largePadding),
            ListTile(
              title: const Text('Başlangıç'),
              subtitle: Text(
                '${_startDate.day}.${_startDate.month}.${_startDate.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            ListTile(
              title: const Text('Bitiş'),
              subtitle: Text(
                '${_endDate.day}.${_endDate.month}.${_endDate.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _endDate = d);
              },
            ),
            const SizedBox(height: Dimens.extraLargePadding),
            AppButton(
              title: _saving ? 'Kaydediliyor...' : 'Oluştur (Onay Bekleyecek)',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
