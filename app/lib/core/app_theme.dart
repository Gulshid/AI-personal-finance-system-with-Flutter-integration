import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for the app: colors, typography, and per-category
/// visual identity (icon + color), so every screen looks consistent without
/// re-deriving styling logic in each widget. Supports both a light and a
/// dark theme; [textPrimary]/[textSecondary]/[surface]/[background] are the
/// *light*-theme values used by widgets that don't yet read from Theme.of.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF0031CA);
  static const Color accent = Color(0xFF00C9A7);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFA726);
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B1F3B);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark theme surface colors
  static const Color darkBackground = Color(0xFF0F1120);
  static const Color darkSurface = Color(0xFF1A1D33);
  static const Color darkTextPrimary = Color(0xFFF2F3F8);
  static const Color darkTextSecondary = Color(0xFF9498B3);

  static TextTheme _textTheme(Color primaryColor, Color secondaryColor) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: primaryColor),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
      bodyMedium: base.bodyMedium?.copyWith(color: secondaryColor, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        error: danger,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: _textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 8,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF7C8CFF),
        secondary: accent,
        error: danger,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
    );

    return base.copyWith(
      textTheme: _textTheme(darkTextPrimary, darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        indicatorColor: primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF7C8CFF) : darkTextSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C8CFF), width: 1.6),
        ),
      ),
    );
  }
}

/// Visual identity (icon + color) for each spending category returned by
/// the API. Falls back gracefully for any category name we don't recognize.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);

  static const Map<String, CategoryStyle> _map = {
    'Dining': CategoryStyle(Icons.restaurant_rounded, Color(0xFFFF7043)),
    'Education': CategoryStyle(Icons.school_rounded, Color(0xFF5C6BC0)),
    'Entertainment': CategoryStyle(Icons.movie_rounded, Color(0xFFAB47BC)),
    'Groceries': CategoryStyle(Icons.local_grocery_store_rounded, Color(0xFF66BB6A)),
    'Healthcare': CategoryStyle(Icons.local_hospital_rounded, Color(0xFFEF5350)),
    'Rent': CategoryStyle(Icons.home_rounded, Color(0xFF8D6E63)),
    'Shopping': CategoryStyle(Icons.shopping_bag_rounded, Color(0xFFEC407A)),
    'Transport': CategoryStyle(Icons.directions_car_rounded, Color(0xFF29B6F6)),
    'Travel': CategoryStyle(Icons.flight_rounded, Color(0xFF26A69A)),
    'Utilities': CategoryStyle(Icons.bolt_rounded, Color(0xFFFFA726)),
  };

  static CategoryStyle of(String category) =>
      _map[category] ?? const CategoryStyle(Icons.category_rounded, Color(0xFF90A4AE));
}

/// Friendly display labels for cluster IDs returned by the model.
/// The model only returns an integer (0, 1, 2, ...); these labels make the
/// dashboard readable. Adjust the wording once you've profiled what each
/// cluster actually represents in your data.
class PersonaStyle {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  const PersonaStyle(this.name, this.description, this.icon, this.color);

  static const List<PersonaStyle> _personas = [
    PersonaStyle('Budget-Conscious Saver', 'Keeps spending lean and predictable',
        Icons.savings_rounded, Color(0xFF66BB6A)),
    PersonaStyle('Balanced Spender', 'Spreads spending evenly across categories',
        Icons.balance_rounded, Color(0xFF42A5F5)),
    PersonaStyle('Lifestyle Spender', 'Spends more on dining, travel & entertainment',
        Icons.local_activity_rounded, Color(0xFFAB47BC)),
    PersonaStyle('Big Spender', 'Highest overall monthly spend',
        Icons.trending_up_rounded, Color(0xFFFF7043)),
  ];

  static PersonaStyle of(int cluster) => _personas[cluster % _personas.length];
}
