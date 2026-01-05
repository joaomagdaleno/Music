buildscript {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
    }
}

allprojects {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
            // Resolve Kotlin version mismatch by forcing stable 2.0.21
            force("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.0.21")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.0.21")
        }
    }
}

subprojects {
    // Inject properties for stability
    project.extensions.extraProperties.set("flutter.compileSdkVersion", 35)
    project.extensions.extraProperties.set("flutter.minSdkVersion", 21)
    project.extensions.extraProperties.set("flutter.targetSdkVersion", 35)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
