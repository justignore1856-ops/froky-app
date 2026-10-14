import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http_inspector/flutter_http_inspector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hyper_commerce/bloc/theme_bloc/theme_bloc.dart';
import 'package:hyper_commerce/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/widgets/cart_state_listener.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'utils/theme_switcher_provider.dart';
import 'app/app_bloc_observer.dart';
import 'app/app_bootstrap.dart';
import 'app/app_startup_listener.dart';
import 'config/dependency_injection_container.dart';
import 'config/global_bloc_providers.dart';
import 'config/global_keys.dart';
import 'config/theme.dart';
import 'config/app_text_styles.dart';
import 'l10n/app_localizations.dart';
import 'screens/support_page/service/support_websocket_connection.dart';

Size responsiveDesignSize(BuildContext context, BoxConstraints constraints) {
  final size = constraints.hasBoundedWidth && constraints.hasBoundedHeight
      ? Size(constraints.maxWidth, constraints.maxHeight)
      : MediaQueryData.fromView(View.of(context)).size;
  if (size.shortestSide < 600) return const Size(360, 690);
  final scale = tabletUiScale(size.shortestSide);
  return Size(size.width / scale, size.height / scale);
}

Future<void> main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint(details.toString());
  };
  await runZonedGuarded(() async {
    await AppBootstrap.initialize();
    setupLocator();
    Bloc.observer = AppBlocObserver();
    if (!kReleaseMode) {
      SupportWebSocketConnection.captureHttpOverridesBeforeInspector();
      HttpInspector.setup();
      runApp(
        ValueListenableBuilder<bool>(
          valueListenable: GlobalKeys.httpInspectorEnabled,
          builder: (context, enabled, child) {
            return HttpInspectorOverlay(
                enabled: enabled,
                child: const MyApp()
            );
          },
        )
      );
    } else {
      runApp(const MyApp());
    }
  }, (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Unhandled app error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStartupListener(
      child: MultiBlocProvider(
        providers: globalBlocProviders(),
        child: const CartStateListener(
          child: _AnimatedThemeWrapper(),
        ),
      ),
    );
  }
}

class _AnimatedThemeWrapper extends StatelessWidget {
  const _AnimatedThemeWrapper();

  @override
  Widget build(BuildContext context) {
    return ThemeSwitcher.switcher(
      builder: (context, switcher) {
        return ThemeSwitcherProvider(
          changeTheme: (theme) => switcher.changeTheme(theme: theme),
          child: BlocBuilder<ThemeBloc, ThemeMode>(
            builder: (context, themeMode) {
              return BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, languageState) {
                  return GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => ScreenUtilInit(
                      designSize: responsiveDesignSize(context, constraints),
                      child: SafeArea(
                        top: false,
                        bottom: defaultTargetPlatform != TargetPlatform.iOS,
                        left: false,
                        right: false,
                        child: Builder(
                          builder: (BuildContext context) {
                            return MaterialApp.router(
                              debugShowCheckedModeBanner: false,
                              scaffoldMessengerKey:
                              GlobalKeys.scaffoldMessengerKey,
                              theme: AppTheme.lightTheme,
                              darkTheme: AppTheme.darkTheme,
                              themeMode: themeMode,
                              builder: (context, child) =>
                                  MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.3,
                                child: FToastBuilder()(context, child),
                              ),
                              routerConfig: MyAppRoute.router,
                              localizationsDelegates:
                              AppLocalizations.localizationsDelegates,
                              supportedLocales: AppLocalizations.supportedLocales,
                              locale: languageState is LanguageLoaded
                                  ? languageState.locale
                                  : const Locale('en'),
                            );
                          },
                        ),
                      ),
                    ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
