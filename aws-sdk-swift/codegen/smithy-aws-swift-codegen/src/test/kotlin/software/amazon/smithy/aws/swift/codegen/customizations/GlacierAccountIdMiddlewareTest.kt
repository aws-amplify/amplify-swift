package software.amazon.smithy.aws.swift.codegen.customizations

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.middleware.GlacierAccountIdMiddleware
import software.amazon.smithy.aws.swift.codegen.newTestContext
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.traits.auth.UnsignedPayloadTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter

class GlacierAccountIdMiddlewareTest {
    @Test
    fun testGlacierMiddlewareRendersCorrectly() {
        val writer = SwiftWriter("testName")
        val serviceShape = ServiceShape.builder()
            .id("com.test#Glacier")
            .version("1.0")
            .build()
        val accountIdMember = MemberShape.builder()
            .id("com.test#TestInputShapeName\$accountId")
            .target("smithy.api#String")
            .build()
        val inputShape = StructureShape.builder()
            .id("com.test#TestInputShapeName")
            .addMember(accountIdMember)
            .build()
        val outputShape = StructureShape.builder().id("com.test#TestOutputShapeName").build()
        val errorShape = StructureShape.builder().id("com.test#TestErrorShapeName").build()
        val operationShape = OperationShape.builder()
            .id("com.test#ExampleOperation")
            .addTrait(UnsignedPayloadTrait())
            .input { ShapeId.from("com.test#TestInputShapeName") }
            .output { ShapeId.from("com.test#TestOutputShapeName") }
            .addError("com.test#TestErrorShapeName")
            .build()
        val model = Model.builder()
            .addShape(serviceShape)
            .addShape(operationShape)
            .addShape(accountIdMember)
            .addShape(inputShape)
            .addShape(outputShape)
            .addShape(errorShape)
            .build()
        val context = model.newTestContext(serviceShapeId = "com.test#Glacier", generator = AWSRestJson1ProtocolGenerator()).ctx
        val opStackName = "stack"
        val glacierMiddleware = GlacierAccountIdMiddleware(model, context.symbolProvider)

        glacierMiddleware.render(context, writer, operationShape, opStackName)

        val contents = writer.toString()
        val expectedContents = """
builder.interceptors.addModifyBeforeSerialization { context in
    let input = context.getInput()
    guard let accountId = input.accountId, !accountId.isEmpty else {
        var copiedInput = input
        copiedInput.accountId = "-"
        context.updateInput(updated: copiedInput)
        return
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
