plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // [WAJIB] Plugin ini yang menghubungkan JSON config ke aplikasi
    id("com.google.gms.google-services")
}

android {
    // Namespace biasanya sama dengan applicationId, tapi tidak wajib sama persis dengan JSON.
    // Yang WAJIB sama dengan JSON adalah applicationId di defaultConfig.
    namespace = "com.aksara.ai"
    
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // [SANGAT PENTING] 
        // Pastikan ID ini SAMA PERSIS dengan "package_name" di google-services.json
        applicationId = "com.aksara.ai" 
        
        minSdk = 24 
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Menggunakan signing config debug untuk rilis sementara (hati-hati untuk produksi)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Tambahkan dependencies native jika diperlukan, 
    // tapi biasanya Flutter sudah menanganinya via pubspec.yaml
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
}