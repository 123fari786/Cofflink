plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Required for Firebase
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = file("C:/Users/ADMIN/Desktop/Project/cofeelink/android/app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("key.properties file not found at ${keystorePropertiesFile.path}")
}


android {
    namespace = "com.cofflink.cofflink"
    compileSdk = 35 // flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.cofflink.cofflink"
        minSdk = flutter.minSdkVersion
        targetSdk = 35 // flutter.targetSdkVersion
        versionCode = 5 // flutter.versionCode
        versionName = "3.2" // flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

 signingConfigs {
    create("release") {
        keyAlias = keystoreProperties.getProperty("keyAlias") ?: throw GradleException("keyAlias missing in key.properties")
        keyPassword = keystoreProperties.getProperty("keyPassword") ?: throw GradleException("keyPassword missing in key.properties")
        storePassword = keystoreProperties.getProperty("storePassword") ?: throw GradleException("storePassword missing in key.properties")

        val storeFilePath = keystoreProperties.getProperty("storeFile") ?: throw GradleException("storeFile missing in key.properties")
        storeFile = file(storeFilePath).also {
            if (!it.exists()) throw GradleException("Keystore file not found at $storeFilePath")
        }
    }
}

   buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
}
