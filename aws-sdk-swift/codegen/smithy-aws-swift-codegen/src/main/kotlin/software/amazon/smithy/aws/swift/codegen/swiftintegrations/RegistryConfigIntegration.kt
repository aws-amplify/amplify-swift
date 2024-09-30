package software.amazon.smithy.aws.swift.codegen.swiftintegrations

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

class RegistryConfigIntegration : SwiftIntegration {

    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean = true

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protocolGenerationContext: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        protocolGenerationContext.delegator.useFileWriter(".swiftpm/configuration/registries.json") { writer ->
            val json = """
            {
              "registries" : {
                "aws-sdk-swift" : {
                  "supportsAvailability" : false,
                  "url" : "https://d1b0xmm48lrxf5.cloudfront.net/"
                }
              },
              "security": {
                "scopeOverrides": {
                  "aws-sdk-swift": {
                  "signing": {
                    "onUnsigned": "silentAllow"
                  }
                }
                }
              },
              "version" : 1
            }
            """.trimIndent()
            writer.write(json)
        }
    }
}
