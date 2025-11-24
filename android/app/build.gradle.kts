plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2" // Latest
}

android {
    namespace = "com.example.btl_ttcs"
    compileSdk = flutter.compileSdkVersion // 34 hoặc 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // BẮT BUỘC cho flutter_local_notifications + java.time API
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.btl_ttcs"
        minSdk = flutter.minSdkVersion // 21 trở lên là tốt nhất
        targetSdk = flutter.targetSdkVersion // 34 hoặc 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // QUAN TRỌNG: Thêm 2 dòng này để tránh crash FCM trên Android 12+
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Dùng debug key để test nhanh
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Thêm đoạn này để tránh lỗi PendingIntent immutable (Android 12+)
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // DÙNG BOM ĐỂ ĐẢM BẢO TẤT CẢ CÁC THƯ VIỆN FIREBASE CÓ CÙNG VERSION
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Các dịch vụ Firebase
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging") // BẮT BUỘC THÊM DÒNG NÀY

    // Desugaring – BẮT BUỘC cho flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")

    // MultiDex (nếu app lớn)
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

// BẮT BUỘC PHẢI CÓ DÒNG NÀY ở cuối file (project-level build.gradle đã có rồi, nhưng để chắc chắn)
apply(plugin = "com.google.gms.google-services")