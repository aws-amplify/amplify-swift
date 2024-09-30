package software.amazon.smithy.aws.swift.codegen.customizations

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.customization.presignable.PresignableUrlIntegration
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class PresignableUrlIntegrationTests {
    @Test
    fun `S3 PutObject operation stack contains the PutObjectPresignedURLMiddleware`() {
        val context = setupTests("presign-urls-s3.smithy", "com.amazonaws.s3#AmazonS3")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/PutObjectInput+Presigner.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
        builder.serialize(PutObjectPresignedURLMiddleware())
        """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `S3 PutObject's PutObjectPresignedURLMiddleware is rendered`() {
        val context = setupTests("presign-urls-s3.smithy", "com.amazonaws.s3#AmazonS3")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/PutObjectInput+QueryItemMiddlewareForPresignUrl.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
public struct PutObjectPresignedURLMiddleware {
    public let id: Swift.String = "PutObjectPresignedURLMiddleware"

    public init() {}
}
extension PutObjectPresignedURLMiddleware: Smithy.RequestMessageSerializer {
    public typealias InputType = PutObjectInput
    public typealias RequestType = SmithyHTTPAPI.HTTPRequest

    public func apply(input: InputType, builder: SmithyHTTPAPI.HTTPRequestBuilder, attributes: Smithy.Context) throws {
        let metadata = input.metadata ?? [:]
        for (metadataKey, metadataValue) in metadata {
            let queryItem = Smithy.URIQueryItem(
                name: "x-amz-meta-\(metadataKey.urlPercentEncoding())",
                value: metadataValue.urlPercentEncoding()
            )
            builder.withQueryItem(queryItem)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestXmlTrait.ID)
        val presigner = PresignableUrlIntegration()
        val generator = AWSRestJson1ProtocolGenerator()

        val codegenContext = GenerationContext(context.ctx.model, context.ctx.symbolProvider, context.ctx.settings, context.manifest, generator)
        val protocolGenerationContext = ProtocolGenerator.GenerationContext(context.ctx.settings, context.ctx.model, context.ctx.service, context.ctx.symbolProvider, listOf(), RestJson1Trait.ID, context.ctx.delegator)
        codegenContext.protocolGenerator?.initializeMiddleware(context.ctx)
        presigner.writeAdditionalFiles(codegenContext, protocolGenerationContext, context.ctx.delegator)
        context.ctx.delegator.flushWriters()
        return context
    }
}
