/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

plugins {
    kotlin("jvm")
    id("org.jetbrains.dokka")
}

allprojects {
    repositories {
        mavenLocal()
        mavenCentral()
    }
}

val ktlint by configurations.creating
val ktlintVersion: String by project
dependencies {
    ktlint("com.pinterest:ktlint:$ktlintVersion")
}

val lintPaths = listOf(
    "codegen/**/*.kt"
)

tasks.register<JavaExec>("ktlint") {
    description = "Check Kotlin code style."
    group = "Verification"
    classpath = configurations.getByName("ktlint")
    main = "com.pinterest.ktlint.Main"
    args = lintPaths
}

tasks.register<JavaExec>("ktlintFormat") {
    description = "Auto fix Kotlin code style violations"
    group = "formatting"
    classpath = configurations.getByName("ktlint")
    main = "com.pinterest.ktlint.Main"
    args = listOf("-F") + lintPaths
}
