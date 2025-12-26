plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.islamicapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "23.1.7779620"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // 🔥 OBLIGATOIRE pour flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.islamicapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ FIX OFFICIEL (JNI / symbols)
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // ⚠️ debug uniquement pour tests
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

/**
 * 🔥 DÉPENDANCES ANDROID
 * (NE PAS SUPPRIMER, NE PAS METTRE DANS android {})
 */
dependencies {
    // 🔑 requis par coreLibraryDesugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
