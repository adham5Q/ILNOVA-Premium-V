@Suppress("UNCHECKED_CAST")
try {
    val peClass = Class.forName("java.lang.ProcessEnvironment")

    val envField = peClass.getDeclaredField("theEnvironment")
    envField.isAccessible = true
    val envMap = envField.get(null) as? MutableMap<String, String>
    envMap?.remove("ANDROID_PREFS_ROOT")

    try {
        val ciEnvField = peClass.getDeclaredField("theCaseInsensitiveEnvironment")
        ciEnvField.isAccessible = true
        val ciEnvMap = ciEnvField.get(null) as? MutableMap<String, String>
        ciEnvMap?.remove("ANDROID_PREFS_ROOT")
    } catch (_: Exception) {}

    try {
        val unmodField = peClass.getDeclaredField("theUnmodifiableEnvironmentMap")
        unmodField.isAccessible = true
        val currentUnmod = unmodField.get(null)
        if (currentUnmod is Map<*, *>) {
            val newMap = HashMap(currentUnmod as Map<String, String>)
            newMap.remove("ANDROID_PREFS_ROOT")
            val collectionsClass = Class.forName("java.util.Collections\$UnmodifiableMap")
            val cons = collectionsClass.getDeclaredConstructor(Map::class.java)
            cons.isAccessible = true
            unmodField.set(null, cons.newInstance(newMap))
        }
    } catch (_: Exception) {}
} catch (_: Exception) {}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
}

include(":app")
