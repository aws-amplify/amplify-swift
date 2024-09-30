package software.amazon.smithy.aws.swift.codegen.awsjson

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait

// The model used in the tests below uses AWS Json 1.0 as the protocol.
// However, AWSJsonHttpResponseBindingErrorGenerator.kt is used for both AWS Json 1.0 and AWS Json 1.1 protocols.
// Therefore, this file tests both versions of AWS Json, 1.0 and 1.1, for the error generation.
class AWSJSONHttpResponseBindingErrorGeneratorTests {
    @Test
    fun `001 GreetingWithErrorsOutputError+HttpResponseBinding`() {
        val context = setupTests("awsjson/json-error.smithy", "aws.protocoltests.json10#AwsJson10")
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
        let baseError = try AWSClientRuntime.AWSJSONError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
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
        val context = setupTests("awsjson/json-error.smithy", "aws.protocoltests.json10#AwsJson10")
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/AwsJson10+HTTPServiceError.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
func httpServiceError(baseError: AWSClientRuntime.AWSJSONError) throws -> Swift.Error? {
    switch baseError.code {
        case "ExampleServiceError": return try ExampleServiceError.makeError(baseError: baseError)
        default: return nil
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, AwsJson1_0Trait.ID)

        AWSJSON1_0ProtocolGenerator().run {
            generateDeserializers(context.ctx)
            generateCodableConformanceForNestedTypes(context.ctx)
        }

        context.ctx.delegator.flushWriters()
        return context
    }
}
