import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/admin_feature/data/services/admin_service.dart';

class AdminRestaurantsScreen extends StatefulWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  State<AdminRestaurantsScreen> createState() => _AdminRestaurantsScreenState();
}

class _AdminRestaurantsScreenState extends State<AdminRestaurantsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _restaurants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _adminService.getRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GeneralAppBar(title: 'Restoran Yönetimi'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimens.largePadding),
                itemCount: _restaurants.length,
                itemBuilder: (context, index) {
                  final r = _restaurants[index] as Map<String, dynamic>;
                  final id = r['restaurantId']?.toString() ?? '';
                  final name = r['name']?.toString() ?? '';
                  final isEnabled = r['isEnabled'] == true;
                  final commissionRate =
                      (r['commissionRate'] ?? 0.10) as num;
                  return Card(
                    margin: const EdgeInsets.only(bottom: Dimens.largePadding),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'Komisyon: %${(commissionRate * 100).toStringAsFixed(1)}',
                      ),
                      trailing: Switch(
                        value: isEnabled,
                        onChanged: (_) async {
                          try {
                            await _adminService.toggleRestaurantStatus(id);
                            if (mounted) _load();
                          } catch (_) {}
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
