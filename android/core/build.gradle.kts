import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
}

// Keep JNI/core packaging aligned with the Flutter invocation. Cached libraries
// for an unrequested ABI must not make this APK claim that ABI is supported.
val avalonTargetAbis = ((findProperty("target-platform") as? String)
    ?: "android-arm,android-arm64,android-x64").split(",").mapNotNull {
    when (it.trim()) {
        "android-arm" -> "armeabi-v7a"
        "android-arm64" -> "arm64-v8a"
        "android-x64" -> "x86_64"
        else -> null
    }
}.toSet()

android {
    namespace = "com.masteralanlab.avalon.core"
    compileSdk = libs.versions.compileSdk.get().toInt()
    ndkVersion = libs.versions.ndkVersion.get()

    defaultConfig {
        ndk { abiFilters.addAll(avalonTargetAbis) }
        minSdk = libs.versions.minSdk.get().toInt()
    }

    externalNativeBuild {
        cmake {
            path("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(libs.annotation.jvm)
}
