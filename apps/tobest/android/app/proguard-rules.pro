# ============================================================
# TO Best — proguard-rules.pro
# قواعد Obfuscation للـ Release APK
# ============================================================

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Isar
-keep class dev.isar.** { *; }
-keepclassmembers class * {
    @dev.isar.annotations.* <fields>;
}

# WorkManager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Kotlin Coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Dio
-keep class com.squareup.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# Pedometer
-keep class com.example.pedometer.** { *; }

# General
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
