/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointTypes
import software.amazon.smithy.swift.codegen.integration.ConfigField
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.clientName
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

const val ENDPOINT_RESOLVER = "endpointResolver"
const val AUTH_SCHEME_RESOLVER = "authSchemeResolver"
const val ENDPOINT_PARAMS = "endpointParams"

class AWSServiceConfig(writer: SwiftWriter, val ctx: ProtocolGenerator.GenerationContext) :
    ServiceConfig(writer, ctx.symbolProvider.toSymbol(ctx.service).name, ctx.service.sdkId) {

    override fun serviceSpecificConfigProperties(): List<ConfigField> {
        var configs = mutableListOf<ConfigField>()

        // service specific EndpointResolver
        configs.add(ConfigField(ENDPOINT_RESOLVER, EndpointTypes.EndpointResolver, "\$N", "Endpoint resolver"))
        // service specific AuthSchemeResolver
        configs.add(ConfigField(AUTH_SCHEME_RESOLVER, buildSymbol { this.name = serviceName.clientName() + "AuthSchemeResolver" }, "\$N"))

        val clientContextParams = ctx.service.getTrait<ClientContextParamsTrait>()
        clientContextParams?.parameters?.forEach {
            configs.add(ConfigField(it.key.toLowerCamelCase(), it.value.type.toSwiftType(), "\$T"))
        }
        return configs.sortedBy { it.memberName }
    }
}

fun ShapeType.toSwiftType(): Symbol {
    return when (this) {
        ShapeType.STRING -> SwiftTypes.String
        ShapeType.BOOLEAN -> SwiftTypes.Bool
        else -> throw IllegalArgumentException("Unsupported shape type: $this")
    }
}
