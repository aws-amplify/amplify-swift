/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.config

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class AWSRegionClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol = AWSClientRuntimeTypes.Core.AWSRegionClientConfiguration

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty(
            "region",
            SwiftTypes.String.toOptional(),
            { it.format("\$N.region(region)", AWSClientRuntimeTypes.Core.AWSClientConfigDefaultsProvider) },
            true,
            true
        ),
        ConfigProperty(
            "signingRegion",
            SwiftTypes.String.toOptional(),
            { it.format("\$N.region(region)", AWSClientRuntimeTypes.Core.AWSClientConfigDefaultsProvider) },
            true,
            true
        )
    )
}
