# Razorpay SDK
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }

# Google Pay / Paisa (these are optional dependencies)
-keep class com.google.android.apps.nbu.paisa.** { *; }
-keepclassmembers class com.google.android.apps.nbu.paisa.** { *; }

# ProGuard annotations
-keep class proguard.annotation.Keep
-keepclassmembers class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
-keepclassmembers class proguard.annotation.KeepClassMembers

# Keep all classes with @Keep annotation
-keep @proguard.annotation.Keep class *
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keepclassmembers class * {
    @proguard.annotation.KeepClassMembers *;
}

# Generic keep rules for common payment/wallet libraries
-keep class **.R$* {
    <fields>;
}
-keep class **.BuildConfig { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }

# Ignore warnings for missing classes (optional dependencies)
-dontwarn com.google.android.apps.nbu.paisa.**
-dontwarn com.razorpay.**
-dontwarn proguard.annotation.**
-dontwarn com.google.firebase.**
-dontwarn com.google.gson.**

# Global: Don't warn about missing or unresolved classes
-ignorewarnings