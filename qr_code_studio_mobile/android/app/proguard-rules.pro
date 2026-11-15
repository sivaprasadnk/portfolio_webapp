# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Google Play Core / In-App Updates
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mlkit.**
-dontwarn androidx.camera.**

# Keep line numbers and source file names for clear crash stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
