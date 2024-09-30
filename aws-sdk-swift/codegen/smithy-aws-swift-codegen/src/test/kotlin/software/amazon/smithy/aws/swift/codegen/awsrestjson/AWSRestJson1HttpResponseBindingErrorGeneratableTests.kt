package software.amazon.smithy.aws.swift.codegen.awsrestjson

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait

class AWSRestJson1HttpResponseBindingErrorGeneratableTests {
    @Test
    fun `001 GreetingWithErrorsOutputError+HttpResponseErrorBinding`() {
        val context = setupTests("awsrestjson1/restjson-error.smithy", "aws.protocoltests.restjson1#RestJson1")
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/GreetingWithErrorsOutputError+HttpResponseErrorBinding.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
enum GreetingWithErrorsOutputError {

    static func httpError(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let baseError = try AWSClientRuntime.RestJSONError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
        if let error = baseError.customError() { return error }
        if let error = try httpServiceError(baseError: baseError) { return error }
        switch baseError.code {
            case "ComplexError": return try ComplexError.makeError(baseError: baseError)
            case "InvalidGreeting": return try InvalidGreeting.makeError(baseError: baseError)
            default: return try AWSClientRuntime.UnknownAWSHTTPServiceError.makeError(baseError: baseError)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 AWSJson+ServiceErrorHelperMethod AWSHttpServiceError`() {
        val context = setupTests("awsrestjson1/restjson-error.smithy", "aws.protocoltests.restjson1#RestJson1")
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/RestJson1+HTTPServiceError.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
func httpServiceError(baseError: AWSClientRuntime.RestJSONError) throws -> Swift.Error? {
    switch baseError.code {
        case "ExampleServiceError": return try ExampleServiceError.makeError(baseError: baseError)
        default: return nil
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)

        AWSRestJson1ProtocolGenerator().run {
            generateDeserializers(context.ctx)
            generateCodableConformanceForNestedTypes(context.ctx)
        }

        context.ctx.delegator.flushWriters()
        return context
    }
}
