plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nova_app"
    compileSdk = 36  // ✅ CAMBIADO de 34 a 36
    ndkVersion = "27.0.12077973"  // ✅ CAMBIADO a la versión requerida

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.nova_app"
        minSdk = flutter.minSdkVersion  // ✅ MANTENEMOS 21 para compatibilidad
        targetSdk = 34  // ✅ PODEMOS mantener 34 (target diferente de compile)
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
