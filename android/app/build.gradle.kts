plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2"
}

android {
    namespace = "com.example.btl_ttcs"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // BẬT DESUGARING ĐỂ DÙNG flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.btl_ttcs"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Dùng debug key để build thử nghiệm
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase Analytics & Firestore
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")

    // THÊM DÒNG NÀY: BẬT DESUGARING CHO LOCAL NOTIFICATIONS
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}