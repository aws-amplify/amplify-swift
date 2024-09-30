/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.config

import software.amazon.smithy.aws.swift.codegen.ENDPOINT_RESOLVER
import software.amazon.smithy.aws.swift.codegen.toSwiftType
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.endpoints.EndpointTypes
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

class AWSEndpointClientConfiguration(val ctx: ProtocolGenerator.GenerationContext) : ClientConfiguration {
    override val swiftProtocolName: Symbol?
        get() = null

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> {
        val properties: MutableSet<ConfigProperty> = mutableSetOf()
        val clientContextParams = ctx.service.getTrait<ClientContextParamsTrait>()
        clientContextParams?.parameters?.forEach {
            properties.add(ConfigProperty(it.key.toLowerCamelCase(), it.value.type.toSwiftType().toOptional()))
        }
        properties.add(
            ConfigProperty(
                ENDPOINT_RESOLVER,
                EndpointTypes.EndpointResolver,
                { it.format("DefaultEndpointResolver()") },
                true
            )
        )
        return properties
    }
}
