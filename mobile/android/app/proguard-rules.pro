# Flutter / Dart VM
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Stripe — reflection-heavy. Keep public API + model classes.
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.android.**

# Firebase (Messaging + Core)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# SignalR (signalr_netcore uses OkHttp + Gson reflection)
-keep class com.microsoft.signalr.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.microsoft.signalr.**

# Keep Retrofit / OkHttp interface methods (used by flutter_stripe transitively)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Play Core (required on Android 14+ with R8)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Kotlin metadata for reflection-based libraries
-keep class kotlin.Metadata { *; }
