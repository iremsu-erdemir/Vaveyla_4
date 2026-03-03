import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/data_source/local/fake_products.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/bloc/cart_cubit.dart';
import 'core/theme/theme.dart';
import 'features/home_feature/presentation/bloc/theme_cubit.dart';
import 'features/home_feature/presentation/screens/splash_screen.dart';

const List<Locale> _supportedAppLocales = <Locale>[
  Locale('tr', 'TR'),
  Locale('en', 'US'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Intl.defaultLocale = 'tr_TR';

  runApp(
    EasyLocalization(
      supportedLocales: _supportedAppLocales,
      path: 'assets/translations',
      useOnlyLangCode: false,
      fallbackLocale: const Locale('tr', 'TR'),
      startLocale: const Locale('tr', 'TR'),
      saveLocale: true,
      useFallbackTranslations: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (final BuildContext context) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode?>(
          builder: (final BuildContext context, final ThemeMode? themeMode) {
            return App(themeMode: themeMode);
          },
        ),
      ),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key, this.themeMode});

  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final locale = context.locale;
    Intl.defaultLocale = '${locale.languageCode}_${locale.countryCode ?? ''}';
    return BlocProvider(
      create:
          (context) =>
              CartCubit()
                ..loadCart()
                ..addItem(FakeProducts.products[0])
                ..addItem(FakeProducts.products[1])
                ..addItem(FakeProducts.products[4])
                ..addItem(FakeProducts.products[6]),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: SplashScreen(),
      ),
    );
  }
}
