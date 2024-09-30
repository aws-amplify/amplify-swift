/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    kotlin("jvm")
    jacoco
}

configurations.implementation {
    exclude(group = "brazil")
}

group = "software.amazon.smithy"
version = "0.1.0"

val smithyVersion: String by project
val kotestVersion: String by project
val smithySwiftVersion: String by project
val junitVersion: String by project
val jacocoVersion: String by project

dependencies {
    implementation(kotlin("stdlib"))
    api("software.amazon.smithy:smithy-swift-codegen:$smithySwiftVersion")
    api("software.amazon.smithy:smithy-aws-traits:$smithyVersion")
    api("software.amazon.smithy:smithy-aws-iam-traits:$smithyVersion")
    api("software.amazon.smithy:smithy-aws-cloudformation-traits:$smithyVersion")
    implementation("software.amazon.smithy:smithy-protocol-test-traits:$smithyVersion")
    testImplementation("org.junit.jupiter:junit-jupiter:$junitVersion")
    testImplementation("io.kotest:kotest-assertions-core-jvm:$kotestVersion")
    implementation("software.amazon.smithy:smithy-rules-engine:$smithyVersion")
    implementation("software.amazon.smithy:smithy-aws-endpoints:$smithyVersion")
}

tasks.withType<KotlinCompile> {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

tasks.withType<JavaCompile> {
    sourceCompatibility = JavaVersion.VERSION_17.toString()
    targetCompatibility = JavaVersion.VERSION_17.toString()
}

jacoco {
    toolVersion = "$jacocoVersion"
}

// Reusable license copySpec
val licenseSpec = copySpec {
    from("${project.rootDir}/LICENSE")
    from("${project.rootDir}/NOTICE")
}

// Configure jars to include license related info
tasks.jar {
    metaInf.with(licenseSpec)
    inputs.property("moduleName", project.name)
    manifest {
        attributes["Automatic-Module-Name"] = project.name
    }
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
    }
}

// Configure jacoco (code coverage) to generate an HTML report
tasks.jacocoTestReport {
    reports {
        xml.isEnabled = false
        csv.isEnabled = false
        html.destination = file("$buildDir/reports/jacoco")
    }
}

// Always run the jacoco test report after testing.
tasks["test"].finalizedBy(tasks["jacocoTestReport"])
