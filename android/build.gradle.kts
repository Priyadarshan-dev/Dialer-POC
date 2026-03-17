allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.withId("com.android.library") {
        configureNamespace(project)
    }
    project.plugins.withId("com.android.application") {
        configureNamespace(project)
    }
}

fun configureNamespace(project: Project) {
    val android = project.extensions.getByName("android")
    try {
        val namespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
        val getNamespaceMethod = android.javaClass.getMethod("getNamespace")
        if (getNamespaceMethod.invoke(android) == null) {
            namespaceMethod.invoke(android, project.group.toString())
        }
    } catch (e: Exception) {
        try {
            val field = android.javaClass.getDeclaredField("namespace")
            field.isAccessible = true
            if (field.get(android) == null) {
                field.set(android, project.group.toString())
            }
        } catch (e2: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
