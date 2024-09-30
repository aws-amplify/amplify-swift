/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSSDKIdentityTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.traits.HttpBearerAuthTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.config.DefaultProvider
import software.amazon.smithy.swift.codegen.integration.HttpProtocolServiceClient
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.model.toGeneric
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAuthAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyIdentityTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRetriesAPITypes
import software.amazon.smithy.swift.codegen.utils.AuthUtils
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

class AWSHttpProtocolServiceClient(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val serviceConfig: ServiceConfig
) : HttpProtocolServiceClient(ctx, writer, serviceConfig) {
    override fun renderConvenienceInitFunctions(serviceSymbol: Symbol) {
        writer.openBlock("public convenience init(region: Swift.String) throws {", "}") {
            writer.write("let config = try ${serviceConfig.typeName}(region: region)")
            writer.write("self.init(config: config)")
        }
        writer.write("")
        writer.openBlock("public convenience required init() async throws {", "}") {
            writer.write("let config = try await ${serviceConfig.typeName}()")
            writer.write("self.init(config: config)")
        }
    }

    override fun overrideConfigProperties(properties: List<ConfigProperty>): List<ConfigProperty> {
        return properties.map {
            when (it.name) {
                "authSchemeResolver" -> {
                    ConfigProperty("authSchemeResolver", SmithyHTTPAuthAPITypes.AuthSchemeResolver, authSchemeResolverDefaultProvider)
                }
                "authSchemes" -> {
                    ConfigProperty("authSchemes", SmithyHTTPAuthAPITypes.AuthSchemes.toOptional(), AWSAuthUtils(ctx).authSchemesDefaultProvider)
                }
                "bearerTokenIdentityResolver" -> {
                    if (AuthUtils(ctx).isSupportedAuthScheme(HttpBearerAuthTrait.ID)) {
                        ConfigProperty(
                            "bearerTokenIdentityResolver",
                            SmithyIdentityTypes.BearerTokenIdentityResolver.toGeneric(),
                            { it.format("\$N()", AWSSDKIdentityTypes.DefaultBearerTokenIdentityResolverChain) },
                            true
                        )
                    } else {
                        it
                    }
                }
                "retryStrategyOptions" -> {
                    ConfigProperty(
                        "retryStrategyOptions",
                        SmithyRetriesAPITypes.RetryStrategyOptions,
                        { it.format("AWSClientConfigDefaultsProvider.retryStrategyOptions(awsRetryMode, maxAttempts)") },
                        true
                    )
                }
                "clientLogMode" -> {
                    ConfigProperty(
                        "clientLogMode",
                        ClientRuntimeTypes.Core.ClientLogMode,
                        { it.format("AWSClientConfigDefaultsProvider.clientLogMode()") },
                    )
                }
                "idempotencyTokenGenerator" -> {
                    ConfigProperty(
                        "idempotencyTokenGenerator",
                        ClientRuntimeTypes.Core.IdempotencyTokenGenerator,
                        { it.format("AWSClientConfigDefaultsProvider.idempotencyTokenGenerator()") },
                    )
                }
                "httpClientEngine" -> {
                    ConfigProperty(
                        "httpClientEngine",
                        SmithyHTTPAPITypes.HttpClient,
                        { it.format("AWSClientConfigDefaultsProvider.httpClientEngine()") },
                    )
                }
                "httpClientConfiguration" -> {
                    ConfigProperty(
                        "httpClientConfiguration",
                        ClientRuntimeTypes.Http.HttpClientConfiguration,
                        { it.format("AWSClientConfigDefaultsProvider.httpClientConfiguration()") },
                    )
                }
                else -> it
            }
        }
    }

    override fun renderCustomConfigInitializer(properties: List<ConfigProperty>) {
        renderRegionConfigInitializer(properties)
    }

    /**
     *  AWS Amplify requires a synchronous initializer with region parameter.
     */
    private fun renderRegionConfigInitializer(properties: List<ConfigProperty>) {
        writer.openBlock("public convenience init(region: String) throws {", "}") {
            writer.write(
                "self.init(\$L)",
                properties.joinToString(", ") {
                    when (it.name) {
                        "region", "signingRegion" -> {
                            "region"
                        }
                        "awsCredentialIdentityResolver" -> {
                            "try AWSClientConfigDefaultsProvider.awsCredentialIdentityResolver()"
                        }
                        "retryStrategyOptions" -> {
                            "try AWSClientConfigDefaultsProvider.retryStrategyOptions()"
                        }
                        else -> {
                            it.default?.render(writer) ?: "nil"
                        }
                    }
                }
            )
        }
        writer.write("")
    }

    private fun renderEmptyAsynchronousConfigInitializer(properties: List<ConfigProperty>) {
        writer.openBlock("public convenience required init() async throws {", "}") {
            writer.write("try await self.init(\$L)", properties.joinToString(", ") { "${it.name}: nil" })
        }
        writer.write("")
    }

    override fun renderPartitionID() {
        writer.openBlock("public var partitionID: String? {", "}") {
            writer.write("return \"\\(\$L.clientName) - \\(region ?? \"\")\"", serviceConfig.clientName.toUpperCamelCase())
        }
    }

    private val authSchemeResolverDefaultProvider = DefaultProvider(
        { "Default${AuthSchemeResolverGenerator.getSdkId(ctx)}AuthSchemeResolver()" },
        false,
        false
    )
}
