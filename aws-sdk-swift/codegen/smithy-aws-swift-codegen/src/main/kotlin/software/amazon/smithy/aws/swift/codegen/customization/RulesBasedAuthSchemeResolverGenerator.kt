package software.amazon.smithy.aws.swift.codegen.customization

import software.amazon.smithy.aws.traits.auth.SigV4ATrait
import software.amazon.smithy.aws.traits.auth.SigV4Trait
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAuthAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

class RulesBasedAuthSchemeResolverGenerator {
    private val AUTH_SCHEME_RESOLVER = "AuthSchemeResolver"
    fun render(ctx: ProtocolGenerator.GenerationContext) {
        ctx.delegator.useFileWriter("Sources/${ctx.settings.moduleName}/$AUTH_SCHEME_RESOLVER.swift") {
            renderServiceSpecificDefaultResolver(ctx, it)
            it.write("")
        }
    }

    private fun renderServiceSpecificDefaultResolver(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        val sdkId = AuthSchemeResolverGenerator.getSdkId(ctx)
        val serviceSpecificDefaultResolverName = "Default$sdkId$AUTH_SCHEME_RESOLVER"
        val serviceSpecificAuthResolverProtocol = sdkId + AUTH_SCHEME_RESOLVER

        writer.apply {
            writer.openBlock(
                "public struct \$L: \$L {",
                "}",
                serviceSpecificDefaultResolverName,
                serviceSpecificAuthResolverProtocol
            ) {
                write("")
                renderResolveAuthSchemeMethod(ctx, writer)
                write("")
                renderConstructParametersMethod(
                    ctx,
                    sdkId + SmithyHTTPAuthAPITypes.AuthSchemeResolverParams.name,
                    writer
                )
            }
        }
    }

    private fun renderResolveAuthSchemeMethod(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        val sdkId = AuthSchemeResolverGenerator.getSdkId(ctx)
        val serviceParamsName = sdkId + SmithyHTTPAuthAPITypes.AuthSchemeResolverParams.name

        writer.apply {
            openBlock(
                "public func resolveAuthScheme(params: \$N) throws -> [\$N] {",
                "}",
                SmithyHTTPAuthAPITypes.AuthSchemeResolverParams,
                SmithyHTTPAuthAPITypes.AuthOption,
            ) {
                // Return value of array of auth options
                write("var validAuthOptions = [\$N]()", SmithyHTTPAuthAPITypes.AuthOption)

                // Cast params to service specific params object
                openBlock(
                    "guard let serviceParams = params as? \$L else {",
                    "}",
                    serviceParamsName
                ) {
                    write(
                        "throw \$N.authError(\"Service specific auth scheme parameters type must be passed to auth scheme resolver.\")",
                        SmithyTypes.ClientError,
                    )
                }

                // Construct endpoint params from auth params
                write("let endpointParams = EndpointParams(authSchemeParams: serviceParams)")
                // Resolve endpoint, and retrieve auth schemes valid for the resolved endpoint
                write("let endpoint = try DefaultEndpointResolver().resolve(params: endpointParams)")
                openBlock("guard let authSchemes = endpoint.authSchemes() else {", "}") {
                    // Call internal modeled model-based auth scheme resolver as fall-back if no auth schemes
                    // are returned by endpoint resolver.
                    write("return try InternalModeled${sdkId + AUTH_SCHEME_RESOLVER}().resolveAuthScheme(params: params)")
                }
                writer.write(
                    "let schemes = try authSchemes.map { (input) -> \$N in try \$N(from: input) }",
                    ClientRuntimeTypes.Core.EndpointsAuthScheme,
                    ClientRuntimeTypes.Core.EndpointsAuthScheme
                )
                // If endpoint resolver returned auth schemes, iterate over them and save each as valid auth option to return
                openBlock("for scheme in schemes {", "}") {
                    openBlock("switch scheme {", "}") {
                        // SigV4 case
                        write("case .sigV4(let param):")
                        indent()
                        write("var sigV4Option = \$N(schemeID: \$S)", SmithyHTTPAuthAPITypes.AuthOption, SigV4Trait.ID)
                        write("sigV4Option.signingProperties.set(key: \$N.signingName, value: param.signingName)", SmithyHTTPAuthAPITypes.SigningPropertyKeys)
                        write("sigV4Option.signingProperties.set(key: \$N.signingRegion, value: param.signingRegion)", SmithyHTTPAuthAPITypes.SigningPropertyKeys)
                        write("validAuthOptions.append(sigV4Option)")
                        dedent()
                        // SigV4A case
                        write("case .sigV4A(let param):")
                        indent()
                        write("var sigV4Option = \$N(schemeID: \$S)", SmithyHTTPAuthAPITypes.AuthOption, SigV4ATrait.ID)
                        write("sigV4Option.signingProperties.set(key: \$N.signingName, value: param.signingName)", SmithyHTTPAuthAPITypes.SigningPropertyKeys)
                        write("sigV4Option.signingProperties.set(key: \$N.signingRegion, value: param.signingRegionSet?[0])", SmithyHTTPAuthAPITypes.SigningPropertyKeys)
                        write("validAuthOptions.append(sigV4Option)")
                        dedent()
                        // Default case: throw error if returned auth scheme is neither SigV4 nor SigV4A
                        write("default:")
                        indent()
                        write("throw \$N.authError(\"Unknown auth scheme name: \\(scheme.name)\")", SmithyTypes.ClientError)
                        dedent()
                    }
                }
                // Return result
                write("return validAuthOptions")
            }
        }
    }

    private fun renderConstructParametersMethod(ctx: ProtocolGenerator.GenerationContext, returnTypeName: String, writer: SwiftWriter) {
        writer.apply {
            openBlock(
                "public func constructParameters(context: \$N) throws -> \$N {",
                "}",
                SmithyTypes.Context,
                SmithyHTTPAuthAPITypes.AuthSchemeResolverParams
            ) {
                openBlock("guard let opName = context.getOperation() else {", "}") {
                    write("throw \$N.dataNotFound(\"Operation name not configured in middleware context for auth scheme resolver params construction.\")", SmithyTypes.ClientError)
                }

                // Get endpoint param from middleware context
                openBlock("guard let endpointParam = context.attributes.get(key: \$N<EndpointParams>(name: \"EndpointParams\")) else {", "}", SmithyTypes.AttributeKey) {
                    write("throw \$N.dataNotFound(\"Endpoint param not configured in middleware context for rules-based auth scheme resolver params construction.\")", SmithyTypes.ClientError)
                }

                // Copy over endpoint param fields to auth param fields
                val ruleSetNode = ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet
                val ruleSet = if (ruleSetNode != null) EndpointRuleSet.fromNode(ruleSetNode) else null
                val paramList = ArrayList<String>()
                ruleSet?.parameters?.toList()?.sortedBy { it.name.toString() }?.let { sortedParameters ->
                    sortedParameters.forEach { param ->
                        val memberName = param.name.toString().toLowerCamelCase()
                        paramList.add("$memberName: endpointParam.$memberName")
                    }
                }

                val argStringToAppend = if (paramList.isEmpty()) "" else ", " + paramList.joinToString()
                write("return $returnTypeName(operation: opName$argStringToAppend)")
            }
        }
    }
}
