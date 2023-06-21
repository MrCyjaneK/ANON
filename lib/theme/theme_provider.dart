import 'package:flutter/material.dart';

const ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffFF6600),
  onPrimary: Color(0xff000000),
  primaryContainer: Color(0xff297ea0),
  onPrimaryContainer: Color(0xffd9edf5),
  secondary: Color(0xffa1e9df),
  onSecondary: Color(0xff030303),
  secondaryContainer: Color(0xff005049),
  onSecondaryContainer: Color(0xffd0e3e1),
  tertiary: Color(0xffa0e5e5),
  onTertiary: Color(0xff181e1e),
  tertiaryContainer: Color(0xff004f50),
  onTertiaryContainer: Color(0xffd0e2e3),
  error: Color(0xffcf6679),
  onError: Color(0xff1e1214),
  errorContainer: Color(0xffb1384e),
  onErrorContainer: Color(0xfff9dde2),
  outline: Color(0xff959999),
  background: Color(0xff000000),
  onBackground: Color(0xffe3e4e4),
  surface: Color(0xff131516),
  onSurface: Color(0xfff1f1f1),
  surfaceVariant: Color(0xff15191b),
  onSurfaceVariant: Color(0xffe3e3e4),
  inverseSurface: Color(0xfffafcfd),
  onInverseSurface: Color(0xff0e0e0e),
  inversePrimary: Color(0xff355967),
  shadow: Color(0xff000000),
);
const barrierColor = Color(0xab1e1e1e);

class ThemeProvider extends ChangeNotifier {
  ThemeData getTheme() {
    return ThemeData(
        colorScheme: colorScheme,
        appBarTheme: const AppBarTheme(color: Colors.transparent),
        primaryColor: colorScheme.primary,
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return colorScheme.primary;
            }
            return null;
          }),
        ),
        fontFamily: 'RobotoMono',
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
          padding: MaterialStateProperty.resolveWith((states) {
            return const EdgeInsets.symmetric(vertical: 14, horizontal: 34);
          }),
          textStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return const TextStyle(
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(
              fontWeight: FontWeight.w500,
            );
          }),
          shape: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10));
            }
            return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8));
          }),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(
          padding: MaterialStateProperty.resolveWith((states) {
            return const EdgeInsets.symmetric(vertical: 14, horizontal: 34);
          }),
          splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
          enableFeedback: true,
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.grey;
            }
            return Colors.white;
          }),
          side: MaterialStateBorderSide.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return const BorderSide(color: Colors.white, width: 1);
            }
            return const BorderSide(color: Color(0xffe7e7e7), width: 0);
          }),
          shape: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white, width: 8));
            }
            return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white, width: 1));
          }),
        )),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey.shade900,
          actionTextColor: colorScheme.primary,
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
            padding: const EdgeInsets.all(8),
            colorScheme: colorScheme.copyWith(
                primary: Colors.white, background: Colors.white)),
        useMaterial3: false);
  }
}
