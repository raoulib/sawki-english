# ProGuard / R8 rules for Sawki English
# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Keep Hive generated adapters
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Don't warn about missing classes in optional dependencies
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.android.play.core.**
