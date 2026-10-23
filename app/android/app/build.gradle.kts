plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.getavalon.avalon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.getavalon.avalon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        // The interface between the app's process and the host service.
        aidl = true
        // BuildConfig.DEBUG: debug builds mirror the core's log to logcat.
        buildConfig = true
    }

    // Release builds never inherit the development key. A missing key produces
    // an unsigned verification APK; a partially configured key is an error.
    val releaseSigning = listOf(
        "AVALON_KEYSTORE_PATH",
        "AVALON_KEY_ALIAS",
        "AVALON_STORE_PASSWORD",
        "AVALON_KEY_PASSWORD",
    ).associateWith { System.getenv(it).orEmpty() }
    val hasReleaseSigning = releaseSigning.values.all { it.isNotEmpty() }
    if (releaseSigning.values.any { it.isNotEmpty() } && !hasReleaseSigning) {
        throw GradleException("All four AVALON release signing variables are required.")
    }
    if (hasReleaseSigning) {
        signingConfigs.create("avalonRelease") {
            storeFile = file(releaseSigning.getValue("AVALON_KEYSTORE_PATH"))
            keyAlias = releaseSigning.getValue("AVALON_KEY_ALIAS")
            storePassword = releaseSigning.getValue("AVALON_STORE_PASSWORD")
            keyPassword = releaseSigning.getValue("AVALON_KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("avalonRelease")
            } else {
                null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// The Core Bridge (sing-box and Avalon's bridge), built from core/ by
// `core/build.sh android`. It is a build product and is not committed.
val coreBridge = rootProject.file("../../core/out/avalon-core.aar")

dependencies {
    implementation(files(coreBridge))
    // Scheduled updates without the interface (D75).
    implementation("androidx.work:work-runtime:2.10.0")
}

tasks.named("preBuild") {
    doFirst {
        if (!coreBridge.exists()) {
            throw GradleException(
                "The Core Bridge is missing: run `core/build.sh tools` once and " +
                    "`core/build.sh android` (see core/README.md)."
            )
        }
        // A bridge older than its sources would run yesterday's protocol.
        val core = rootProject.file("../../core")
        val newer = listOf("bridge", "mobile")
            .flatMap { core.resolve(it).walkTopDown().filter { f -> f.isFile && !f.name.endsWith("_test.go") } }
            .plus(listOf(core.resolve("go.mod"), core.resolve("BUILD_TAGS")))
            .filter { it.lastModified() > coreBridge.lastModified() }
        if (newer.isNotEmpty()) {
            throw GradleException(
                "The Core Bridge is older than its sources (${newer.first().name}): " +
                    "run `core/build.sh android` again."
            )
        }
    }
}
