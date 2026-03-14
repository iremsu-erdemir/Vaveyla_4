import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/sized_context.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_search_bar.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_svg_viewer.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_rating_summary.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/screens/sort_and_filter_screen.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/dimens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/general_app_bar.dart';
import '../../../../core/widgets/shaded_container.dart';
import '../../data/services/products_service.dart';
import '../bloc/all_products_cubit.dart';
import '../models/products_filter.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/widgets/product_image_widget.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.initialType, this.title = 'Ürünler'});

  final String? initialType;
  final String title;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const _closedRestaurantMessage =
      'Bu pastane şu anda hizmet verememektedir.';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.topRated;
  String? _selectedCategory;
  double? _userLat;
  double? _userLng;
  bool _isResolvingLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureCurrentLocation() async {
    if (_userLat != null && _userLng != null) {
      return;
    }
    if (_isResolvingLocation) {
      return;
    }
    setState(() => _isResolvingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (_) {
      // If location fails, keep default ordering.
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  List<ProductModel> _applyFilter(List<ProductModel> products) {
    final query = _searchQuery.trim().toLowerCase();
    var filtered =
        products.where((product) {
          final name = product.name.toString().toLowerCase();
          final category =
              (product.categoryName?.toString() ?? '').toLowerCase();
          final categoryMatches =
              _selectedCategory == null ||
              _selectedCategory!.isEmpty ||
              (product.categoryName?.toString() ?? '').toLowerCase() ==
                  _selectedCategory!.toLowerCase();
          final searchMatches =
              query.isEmpty || name.contains(query) || category.contains(query);
          return categoryMatches && searchMatches;
        }).toList();

    switch (_sortOption) {
      case ProductSortOption.topRated:
        filtered.sort((a, b) => b.rate.compareTo(a.rate));
        break;
      case ProductSortOption.cheapest:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.newest:
        // Backend default order is newest first.
        break;
      case ProductSortOption.nearest:
        if (_userLat == null || _userLng == null) {
          break;
        }
        filtered.sort((a, b) {
          final aLat = a.restaurantLat;
          final aLng = a.restaurantLng;
          final bLat = b.restaurantLat;
          final bLng = b.restaurantLng;
          if (aLat == null || aLng == null) return 1;
          if (bLat == null || bLng == null) return -1;
          final distA = _distanceKm(_userLat!, _userLng!, aLat, aLng);
          final distB = _distanceKm(_userLat!, _userLng!, bLat, bLng);
          return distA.compareTo(distB);
        });
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              AllProductsCubit(ProductsService())
                ..loadProducts(type: widget.initialType)
                ..startPolling(),
      child: AppScaffold(
        appBar: GeneralAppBar(
          title: widget.title,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.only(
                left: Dimens.largePadding,
                right: Dimens.largePadding,
              ),
              child: AppSearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          height: 128,
        ),
        body: Column(
          spacing: Dimens.largePadding,
          children: [
            SizedBox.shrink(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: Dimens.largePadding,
              children: [
                GestureDetector(
                  onTap: () async {
                    final state = context.read<AllProductsCubit>().state;
                    final categories =
                        state.products
                            .map((x) => x.categoryName?.trim() ?? '')
                            .where((x) => x.isNotEmpty)
                            .toSet()
                            .toList()
                          ..sort();
                    final result = await appPush(
                      context,
                      SortAndFilterScreen(
                        categories: categories,
                        initialSort: _sortOption,
                        initialCategory: _selectedCategory,
                      ),
                    );
                    if (result is ProductsFilter && mounted) {
                      setState(() {
                        _sortOption = result.sort;
                        _selectedCategory = result.category;
                      });
                      if (result.sort == ProductSortOption.nearest) {
                        _ensureCurrentLocation();
                      }
                    }
                  },
                  child: ShadedContainer(
                    padding: EdgeInsets.all(Dimens.largePadding),
                    borderRadius: 100,
                    child: Row(
                      spacing: Dimens.padding,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgViewer(Assets.icons.filterSearch, width: 16),
                        Text('Filtreler'),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final state = context.read<AllProductsCubit>().state;
                    final categories =
                        state.products
                            .map((x) => x.categoryName?.trim() ?? '')
                            .where((x) => x.isNotEmpty)
                            .toSet()
                            .toList()
                          ..sort();
                    final result = await appPush(
                      context,
                      SortAndFilterScreen(
                        categories: categories,
                        initialSort: _sortOption,
                        initialCategory: _selectedCategory,
                      ),
                    );
                    if (result is ProductsFilter && mounted) {
                      setState(() {
                        _sortOption = result.sort;
                        _selectedCategory = result.category;
                      });
                      if (result.sort == ProductSortOption.nearest) {
                        _ensureCurrentLocation();
                      }
                    }
                  },
                  child: ShadedContainer(
                    padding: EdgeInsets.all(Dimens.largePadding),
                    borderRadius: 100,
                    child: Row(
                      spacing: Dimens.padding,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgViewer(Assets.icons.sort, width: 16),
                        Text('Sırala'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: BlocBuilder<AllProductsCubit, AllProductsState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_sortOption == ProductSortOption.nearest &&
                      _isResolvingLocation) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = _applyFilter(state.products);
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null
                            ? 'Arama/filtreye uygun ürün bulunamadı.'
                            : 'Henüz ürün bulunamadı.',
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: Dimens.largePadding,
                      crossAxisSpacing: Dimens.largePadding,
                      mainAxisExtent: 210,
                    ),
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (final context, final index) {
                      final product = products[index];
                      final isRestaurantOpen = product.restaurantIsOpen;
                      return InkWell(
                        onTap: () {
                          if (!isRestaurantOpen) {
                            context.showErrorMessage(_closedRestaurantMessage);
                            return;
                          }
                          appPush(
                            context,
                            ProductDetailsScreen(product: product),
                          );
                        },
                        borderRadius: BorderRadius.circular(Dimens.corners),
                        child: ShadedContainer(
                          child: Stack(
                            children: [
                              Column(
                                spacing: Dimens.padding,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      Dimens.padding,
                                    ),
                                    child: SizedBox(
                                      height: 114,
                                      width: context.widthPx,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Dimens.corners,
                                        ),
                                        child: _buildProductImage(
                                          context,
                                          product.imageUrl,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimens.padding,
                                    ),
                                    child: Column(
                                      spacing: Dimens.largePadding,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          spacing: Dimens.padding,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style:
                                                    context
                                                        .theme
                                                        .appTypography
                                                        .titleSmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            AppRatingSummary(
                                              rating: product.rate,
                                              reviewCount: product.reviewCount,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatPrice(product.price),
                                              style: context
                                                  .theme
                                                  .appTypography
                                                  .labelLarge
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (!isRestaurantOpen)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      color: Colors.grey.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: Dimens.padding,
                                right: Dimens.padding,
                                child: Visibility(
                                  visible: !isRestaurantOpen,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimens.smallPadding,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Dimens.smallCorners,
                                      ),
                                    ),
                                    child: Text(
                                      'Kapalı',
                                      style: context
                                          .theme
                                          .appTypography
                                          .labelSmall
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(context),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(context),
      );
    }
    return buildProductImage(imageUrl, 200, 114);
  }

  Widget _placeholderImage(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }
}
