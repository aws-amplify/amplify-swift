package software.amazon.smithy.aws.swift.codegen.plugins

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointTypes
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

class EndpointPlugin(private val serviceConfig: ServiceConfig) : Plugin {

    private val pluginName: String = "${serviceConfig.clientName.toUpperCamelCase()}EndpointPlugin"

    override val className: Symbol
        get() = buildSymbol {
            this.name = pluginName
        }

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        writer.openBlock("public class $pluginName: Plugin {", "}") {
            writer.write("private var endpointResolver: \$L", EndpointTypes.EndpointResolver)
            writer.write("")
            writer.openBlock("public init(endpointResolver: \$L) {", "}", EndpointTypes.EndpointResolver) {
                writer.write("self.endpointResolver = endpointResolver")
            }
            writer.write("")
            writer.openBlock("public convenience init() throws {", "}") {
                writer.write("self.init(endpointResolver: try \$L())", EndpointTypes.DefaultEndpointResolver)
            }
            writer.write("")
            writer.openBlock("public func configureClient(clientConfiguration: ClientRuntime.ClientConfiguration) throws {", "}") {
                writer.openBlock("if let config = clientConfiguration as? ${serviceConfig.typeName} {", "}") {
                    writer.write("config.endpointResolver = self.endpointResolver")
                }
            }
        }
        writer.write("")
    }
}
