buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
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
