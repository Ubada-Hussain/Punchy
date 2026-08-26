# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods and JNI bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Mobile Scanner & NFC Manager
-keep class dev.nfc.** { *; }
-keep class dev.zxing.** { *; }
-keep class com.google.mlkit.** { *; }

# Generated Plugin Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

-dontwarn io.flutter.embedding.**
-dontwarn com.google.mlkit.**
