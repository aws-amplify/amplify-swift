package software.amazon.smithy.aws.swift.codegen.swiftintegrations

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

class PackageVersionIntegration : SwiftIntegration {

    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean = true

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protocolGenerationContext: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        val path = "Sources/${ctx.settings.moduleName}/Resources/Package.version"
        protocolGenerationContext.delegator.useFileWriter(path) { writer ->
            writer.writeInline(ctx.settings.moduleVersion)
        }
    }
}
