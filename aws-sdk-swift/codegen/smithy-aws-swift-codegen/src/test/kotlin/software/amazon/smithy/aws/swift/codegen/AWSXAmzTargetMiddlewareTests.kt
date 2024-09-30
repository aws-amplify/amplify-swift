/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.middleware.AWSXAmzTargetMiddleware
import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.aws.traits.auth.UnsignedPayloadTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter

class AWSXAmzTargetMiddlewareTests {
    @Test
    fun `xAmzTargetMiddleware happypath`() {
        val expectedContents = """
builder.interceptors.add(AWSClientRuntime.XAmzTargetMiddleware<TestInputShapeName, TestOutputShapeName>(xAmzTarget: "ExampleServiceShapeName.ExampleOperation"))
"""
        val writer = SwiftWriter("testName")
        val serviceShape = ServiceShape.builder()
            .id("com.test#ExampleServiceShapeName")
            .version("1.0")
            .build()
        val inputShape = StructureShape.builder().id("com.test#TestInputShapeName").build()
        val outputShape = StructureShape.builder().id("com.test#TestOutputShapeName").build()
        val errorShape = StructureShape.builder().id("com.test#TestErrorShapeName").build()
        val operationShape = OperationShape.builder()
            .id("com.test#ExampleOperation")
            .addTrait(UnsignedPayloadTrait())
            .input { ShapeId.from("com.test#TestInputShapeName") }
            .output { ShapeId.from("com.test#TestOutputShapeName") }
            .addError("com.test#TestErrorShapeName")
            .build()
        val opStackName = "stack"
        val model = Model
            .builder()
            .addShape(serviceShape)
            .addShape(operationShape)
            .addShape(inputShape)
            .addShape(outputShape)
            .addShape(errorShape)
            .build()
        val context = model.newTestContext("com.test#ExampleServiceShapeName", AWSJSON1_0ProtocolGenerator()).ctx
        val sut = AWSXAmzTargetMiddleware(context.model, context.symbolProvider, context.service)

        sut.render(context, writer, operationShape, opStackName)

        val contents = writer.toString()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
