import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val mapsApiKey =
    localProperties.getProperty("MAPS_API_KEY")
        ?: keystoreProperties.getProperty("MAPS_API_KEY")
        ?: System.getenv("MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.femalecar.eon"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        multiDexEnabled = true
        applicationId = "com.femalecar.eon"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val rawStoreFile = keystoreProperties["storeFile"] as String?
            storeFile = rawStoreFile?.let { path ->
                val direct = file(path)
                if (direct.exists()) direct
                else {
                    val rootLevel = rootProject.file(path)
                    if (rootLevel.exists()) rootLevel
                    else rootProject.file("../$path")
                }
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // This block runs at configuration time for EVERY build, so only fail when a
            // release build was actually requested (debug builds must work without the key).
            if (mapsApiKey.isBlank()) {
                val releaseRequested = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
                if (releaseRequested) {
                    throw GradleException("Missing MAPS_API_KEY. Set it in android/local.properties, android/key.properties, or environment variable MAPS_API_KEY.")
                } else {
                    logger.warn("WARNING: MAPS_API_KEY is not set; Google Maps will not work in this build.")
                }
            }
            // Signing is optional: without a complete key.properties/keystore the
            // build still succeeds and produces an UNSIGNED release APK/AAB.
            val releaseSigning = signingConfigs.getByName("release")
            val isSigningConfigured = keystorePropertiesFile.exists() &&
                releaseSigning.storeFile?.exists() == true &&
                !releaseSigning.keyAlias.isNullOrBlank() &&
                !releaseSigning.keyPassword.isNullOrBlank() &&
                !releaseSigning.storePassword.isNullOrBlank()

            if (isSigningConfigured) {
                signingConfig = releaseSigning
            } else {
                logger.warn("WARNING: release keystore not configured (android/key.properties); building an UNSIGNED release.")
            }
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
}
