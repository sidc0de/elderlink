import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/logo_splash_screen.dart';
import 'state/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await LocaleController.load();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider.value(
      value: localeController,
      child: const ElderLinkApp(),
    ),
  );
}

class ElderLinkApp extends StatelessWidget {
  const ElderLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleController>(
      builder: (context, localeController, _) {
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.t('appTitle'),
          debugShowCheckedModeBanner: false,
          theme: ElderLinkTheme.lightTheme(localeController.locale),
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LogoSplashScreen(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  THEME
// ─────────────────────────────────────────────
class ElderLinkTheme {
  // Brand colors
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF9E5E);
  static const Color purple = Color(0xFF7C5CBF);
  static const Color purpleLight = Color(0xFFa07fd4);
  static const Color darkNavy = Color(0xFF1a1a2e);
  static const Color midNavy = Color(0xFF16213e);
  static const Color deepBlue = Color(0xFF0f3460);
  static const Color green = Color(0xFF2ECC71);

  // Neutral
  static const Color background = Color(0xFFF8F9FC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1a1a2e);
  static const Color textSecondary = Color(0xFF5F6C7B);
  static const Color borderLight = Color(0xFFE4E8EF);
  static const Color surfaceMuted = Color(0xFFF3F5F9);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFA32D2D);

  // Status colors
  static const Color statusPending = Color(0xFFFFF8E1);
  static const Color statusPendingText = Color(0xFFF9A825);
  static const Color statusAccepted = Color(0xFFE8F5E9);
  static const Color statusAcceptedText = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFFE3F2FD);
  static const Color statusCompletedText = Color(0xFF1565C0);

  static ThemeData lightTheme(Locale locale) {
    final useDevanagari =
        locale.languageCode == 'hi' || locale.languageCode == 'mr';
    final baseSeedTextTheme = useDevanagari
        ? GoogleFonts.notoSansDevanagariTextTheme()
        : GoogleFonts.poppinsTextTheme();
    final baseTextTheme = baseSeedTextTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1,
      ),
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.55,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: useDevanagari
          ? GoogleFonts.notoSansDevanagari().fontFamily
          : GoogleFonts.poppins().fontFamily,

      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        primary: orange,
        secondary: purple,
        background: background,
        surface: cardWhite,
        outlineVariant: borderLight,
      ),

      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme,
      splashColor: orange.withOpacity(0.08),
      highlightColor: orange.withOpacity(0.05),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orange,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: const BorderSide(color: borderLight, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: orange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: orange,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cardWhite,
        selectedColor: const Color(0xFFFFF5F2),
        side: const BorderSide(color: borderLight, width: 1.2),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      dividerColor: borderLight,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? orange : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? orange.withOpacity(0.35)
              : borderLight;
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP CONSTANTS
// ─────────────────────────────────────────────
class AppConstants {
  // Padding & spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 20.0;
  static const double paddingXL = 24.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 100.0;

  // Card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF152033).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: ElderLinkTheme.orange.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

// ─────────────────────────────────────────────
//  USER ROLES ENUM
// ─────────────────────────────────────────────
enum UserRole { elder, volunteer, family }

// ─────────────────────────────────────────────
//  REQUEST STATUS ENUM
// ─────────────────────────────────────────────
enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

// ─────────────────────────────────────────────
//  REQUEST CATEGORY ENUM
// ─────────────────────────────────────────────
enum RequestCategory {
  medicine,
  grocery,
  transport,
  companionship,
  doctorVisit,
  errand,
}

extension RequestCategoryExtension on RequestCategory {
  String get label {
    switch (this) {
      case RequestCategory.medicine:
        return 'Medicine';
      case RequestCategory.grocery:
        return 'Grocery';
      case RequestCategory.transport:
        return 'Transport';
      case RequestCategory.companionship:
        return 'Companionship';
      case RequestCategory.doctorVisit:
        return 'Doctor Visit';
      case RequestCategory.errand:
        return 'Errand';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case RequestCategory.medicine:
        return l10n.t('medicine');
      case RequestCategory.grocery:
        return l10n.t('grocery');
      case RequestCategory.transport:
        return l10n.t('transport');
      case RequestCategory.companionship:
        return l10n.t('companionship');
      case RequestCategory.doctorVisit:
        return l10n.t('doctorVisit');
      case RequestCategory.errand:
        return l10n.t('errand');
    }
  }

  String get emoji {
    switch (this) {
      case RequestCategory.medicine:
        return '💊';
      case RequestCategory.grocery:
        return '🛒';
      case RequestCategory.transport:
        return '🚗';
      case RequestCategory.companionship:
        return '🗣️';
      case RequestCategory.doctorVisit:
        return '🏥';
      case RequestCategory.errand:
        return '📦';
    }
  }

  Color get color {
    switch (this) {
      case RequestCategory.medicine:
        return const Color(0xFFFF6B35);
      case RequestCategory.grocery:
        return const Color(0xFF2ECC71);
      case RequestCategory.transport:
        return const Color(0xFF1565C0);
      case RequestCategory.companionship:
        return const Color(0xFF7C5CBF);
      case RequestCategory.doctorVisit:
        return const Color(0xFFE24B4A);
      case RequestCategory.errand:
        return const Color(0xFF2ECC71);
    }
  }

  Color get bgColor {
    switch (this) {
      case RequestCategory.medicine:
        return const Color(0xFFFFF0EB);
      case RequestCategory.grocery:
        return const Color(0xFFEDFAF3);
      case RequestCategory.transport:
        return const Color(0xFFE3F2FD);
      case RequestCategory.companionship:
        return const Color(0xFFF0F4FF);
      case RequestCategory.doctorVisit:
        return const Color(0xFFFCEBEB);
      case RequestCategory.errand:
        return const Color(0xFFEDFAF3);
    }
  }
}
