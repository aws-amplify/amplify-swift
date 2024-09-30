/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

open class ProtocolTestTask : DefaultTask() {
    @get:Input
    var protocol: String = ""

    @get:Input
    var plugin: String = ""

    @TaskAction
    fun runTests(){
        require(protocol.isNotEmpty()) { "protocol name must be specified" }
        require(plugin.isNotEmpty()) { "plugin name must be specified" }

        val generatedBuildDir = project.file("${project.buildDir}/smithyprojections/${project.name}/$protocol/$plugin")
        println("[$protocol] buildDir: $generatedBuildDir")
        if (!generatedBuildDir.exists()) {
            throw GradleException("$generatedBuildDir does not exist")
        }

        project.exec {
            workingDir = generatedBuildDir
            executable = "cat"
            args = listOf("Package.swift")
        }

        // build including tests
        project.exec {
            workingDir = generatedBuildDir
            executable = "swift"
            args = listOf("build", "--build-tests")
        }

        // run tests if test target exists
        // test target directory ends with "Tests"
        val testTargetDir = generatedBuildDir.listFiles().firstOrNull { it.name.endsWith("Tests") }
        if (testTargetDir == null) {
            println("[$protocol] no test target found")
            return
        }

        // test without building
        project.exec {
            workingDir = generatedBuildDir
            executable = "swift"
            args = listOf("test", "--skip-build")
        }
    }
}