pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    } catch (e: Exception) {
        throw GradleException("Flutter SDK not found.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // UPGRADE AGP KE 8.9.1 (Agar support SDK 36)
    id("com.android.application") version "8.9.1" apply false 
    // UPGRADE KOTLIN KE 2.1.0
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")