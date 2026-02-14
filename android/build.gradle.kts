// ✅ Required for Firebase & Google services
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}

// ✅ Repository configuration for all modules
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Unified build directory (recommended for Flutter)
val newBuildDir = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// ✅ Apply same build directory structure to subprojects
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ Ensure app module is evaluated first
subprojects {
    evaluationDependsOn(":app")
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
