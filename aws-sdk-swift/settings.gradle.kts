/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

pluginManagement {
    repositories {
        mavenCentral()
	maven("https://plugins.gradle.org/m2/")
	google()
        gradlePluginPortal()
    }

    plugins {
        val kotlinVersion: String by settings
        val dokkaVersion: String by settings
        val kotlinxBenchmarkVersion: String by settings
        val smithyGradleVersion: String by settings
        id("org.jetbrains.dokka") version dokkaVersion
        id("org.jetbrains.kotlin.jvm") version kotlinVersion
        id("org.jetbrains.kotlinx.benchmark") version kotlinxBenchmarkVersion
        id("software.amazon.smithy") version smithyGradleVersion
    }
}

rootProject.name = "aws-sdk-swift"


fun module(path: String) {
    val name = path.replace('\\', '/').substringAfterLast('/')
    include(name)
    project(":$name").projectDir = file(path)
}


module("codegen")
module("codegen/sdk-codegen")
module("codegen/smithy-aws-swift-codegen")
module("codegen/protocol-test-codegen")
module("codegen/protocol-test-codegen-local")

/**
 * The following code enables to optionally include aws-sdk-swift dependencies in source form for easier
 * development.  By default, if `smithy-swift` exists as a directory at the same level as `aws-sdk-swift`
 * then `smithy-swift` will be added as a composite build.  To override this behavior, for example to add
 * more composite builds, specify a different directory for `smithy-swift`, or to disable the feature entirely,
 * a local.properties file can be added or amended such that the property `compositeProjects` specifies
 * a comma delimited list of paths to project roots that shall be added as composite builds.  If the list is
 * empty to builds will be added.  Invalid directories are ignored.  Example local.properties:
 *
 * compositeProjects=~/repos/smithy-swift,/tmp/some/other/thing,../../another/project
 *
 */
val compositeProjectList = try {
    val localProperties = java.util.Properties()
    localProperties.load(File(rootProject.projectDir, "local.properties").inputStream())
    val filePaths = localProperties.getProperty("compositeProjects")
        ?.splitToSequence(",")  // Split comma delimited string into sequence
        ?.map { it.replaceFirst("^~".toRegex(), System.getProperty("user.home")) } // expand user dir
        ?.map { file(it) } // Create file from path
        ?.toList()
        ?: emptyList()

    if (filePaths.isNotEmpty()) println("Adding ${filePaths.size} composite build directories from local.properties.")
    filePaths
} catch (e: java.io.FileNotFoundException) {
    listOf(file("../smithy-swift")) // Default path, not an error.
} catch (e: Throwable) {
    logger.error("Failed to load project paths from local.properties. Assuming defaults.", e)
    listOf(file("../smithy-swift"))
}

compositeProjectList.forEach { projectRoot ->
    when (projectRoot.exists()) {
        true -> {
            println("Including build '$projectRoot'")
            includeBuild(projectRoot)
        }
        false -> println("Ignoring invalid build directory '$projectRoot'.")
    }
}
