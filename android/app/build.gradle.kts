plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Thêm plugin Google Services với phiên bản cụ thể
    id("com.google.gms.google-services") version "4.4.2"
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Thêm dependencies cho các sản phẩm Firebase bạn muốn dùng
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore") // Thêm Firestore

    // Có thể thêm các sản phẩm khác nếu cần
    // Xem: https://firebase.google.com/docs/android/setup#available-libraries
}

android {
    namespace = "com.example.btl_ttcs"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
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
            // Xóa hoặc sửa signingConfig nếu chưa cấu hình khóa ký
            // Nếu chưa có keystore, để trống hoặc dùng debug cho thử nghiệm
            // signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}