package software.amazon.smithy.aws.swift.codegen

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.auth.SigV4Trait
import software.amazon.smithy.aws.traits.auth.UnsignedPayloadTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.AuthTrait
import software.amazon.smithy.model.traits.HttpBasicAuthTrait

class AWSAuthUtilsTests {
    @Test
    fun `service has SigV4Trait and operation has auth trait`() {
        val sigV4Trait = SigV4Trait.builder().name("ExampleService").build()
        val authList = listOf(HttpBasicAuthTrait().toShapeId(), sigV4Trait.toShapeId())

        val serviceShape = ServiceShape.builder()
            .id("com.test#Example")
            .version("1.0")
            .addTrait(sigV4Trait)
            .build()
        val operationShape = OperationShape.builder()
            .id("com.test#ExampleOperation")
            .addTrait(UnsignedPayloadTrait())
            .addTrait(AuthTrait(authList))
            .build()
        val model = Model.builder()
            .addShape(serviceShape)
            .addShape(operationShape)
            .build()

        val hasAuthScheme = AWSAuthUtils.hasSigV4AuthScheme(model, serviceShape, operationShape)
        assertTrue(hasAuthScheme)
    }

    @Test
    fun `service has SigV4trait but operation does not have auth`() {
        val serviceShape = ServiceShape.builder()
            .id("com.test#Example")
            .version("1.0")
            .addTrait(SigV4Trait.builder().name("ExampleService").build())
            .build()
        val outputShape = StructureShape.builder()
            .id("com.test#ExampleOutput")
            .build()
        val operationShape = OperationShape.builder()
            .id("com.test#ExampleOperation")
            .output { ShapeId.from("com.test#ExampleOutput") }
            .build()
        val model = Model.builder()
            .addShape(serviceShape)
            .addShape(operationShape)
            .addShape(outputShape)
            .build()

        val hasAuthScheme = AWSAuthUtils.hasSigV4AuthScheme(model, serviceShape, operationShape)
        assertFalse(hasAuthScheme)
    }
}
