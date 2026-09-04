import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ======================================================
// LOAD KEYSTORE PROPERTIES
// ======================================================

val keystoreProperties = Properties()

val keystorePropertiesFile =
    rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

// ======================================================
// ANDROID
// ======================================================

android {
    namespace = "com.anil.demo_vehicle_management"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId =
            "com.anil.demo_vehicle_management"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ==================================================
    // RELEASE SIGNING
    // ==================================================

    signingConfigs {
        create("release") {

            val keyAliasValue =
                keystoreProperties
                    .getProperty("keyAlias")

            val keyPasswordValue =
                keystoreProperties
                    .getProperty("keyPassword")

            val storeFileValue =
                keystoreProperties
                    .getProperty("storeFile")

            val storePasswordValue =
                keystoreProperties
                    .getProperty("storePassword")

            if (keyAliasValue.isNullOrBlank()) {
                throw GradleException(
                    "keyAlias missing in android/key.properties"
                )
            }

            if (keyPasswordValue.isNullOrBlank()) {
                throw GradleException(
                    "keyPassword missing in android/key.properties"
                )
            }

            if (storeFileValue.isNullOrBlank()) {
                throw GradleException(
                    "storeFile missing in android/key.properties"
                )
            }

            if (storePasswordValue.isNullOrBlank()) {
                throw GradleException(
                    "storePassword missing in android/key.properties"
                )
            }

            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue

            storeFile = file(
                storeFileValue
            )

            storePassword = storePasswordValue
        }
    }

    // ==================================================
    // BUILD TYPES
    // ==================================================

    buildTypes {
        getByName("release") {

            signingConfig =
                signingConfigs.getByName("release")

            isMinifyEnabled = false

            isShrinkResources = false
        }
    }
}

// ======================================================
// FLUTTER
// ======================================================

flutter {
    source = "../.."
}