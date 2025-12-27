buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // Inject properties to satisfy plugin requirements
    project.extensions.extraProperties.set("flutter.compileSdkVersion", 36)
    project.extensions.extraProperties.set("flutter.minSdkVersion", 21)
    project.extensions.extraProperties.set("flutter.targetSdkVersion", 36)
    project.extensions.extraProperties.set("flutter.ndkVersion", "28.2.13676358")

    // Aggressive injection for plugins applied now or in the future
    plugins.withId("com.android.library") {
        configureAndroidExtension(project)
    }
    plugins.withId("com.android.application") {
        configureAndroidExtension(project)
    }

    afterEvaluate {
        configureAndroidExtension(project)
    }
}

fun configureAndroidExtension(project: Project) {
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            // Set compileSdk using reflection to avoid classpath issues
            val compileSdkMethod = android.javaClass.methods.find { it.name == "setCompileSdk" && it.parameterCount == 1 }
            compileSdkMethod?.invoke(android, 36)
            
            // Set namespace if null or invalid provider
            val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" && it.parameterCount == 0 }
            val currentNamespace = getNamespace?.invoke(android)
            if (currentNamespace == null || (currentNamespace is org.gradle.api.provider.Provider<*> && !currentNamespace.isPresent)) {
                val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" && it.parameterCount == 1 }
                val name = project.name.replace(":", ".").replace("-", ".")
                setNamespace?.invoke(android, "com.fix.$name")
            }
        } catch (e: Exception) {
            // Ignore failures for non-Android or unusual structures
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
