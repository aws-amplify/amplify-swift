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
import software.amazon.smithy.swift.codegen.model.toGeneric
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyIdentityTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class AWSDefaultClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol = AWSClientRuntimeTypes.Core.AWSDefaultClientConfiguration

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty("useFIPS", SwiftTypes.Bool.toOptional()),
        ConfigProperty("useDualStack", SwiftTypes.Bool.toOptional()),
        ConfigProperty(
            "appID",
            SwiftTypes.String.toOptional(),
            { it.format("\$N.appID()", AWSClientRuntimeTypes.Core.AWSClientConfigDefaultsProvider) },
            true
        ),
        ConfigProperty(
            "awsCredentialIdentityResolver",
            SmithyIdentityTypes.AWSCredentialIdentityResolver.toGeneric(),
            { it.format("\$N.awsCredentialIdentityResolver(awsCredentialIdentityResolver)", AWSClientRuntimeTypes.Core.AWSClientConfigDefaultsProvider) },
            true
        ),
        ConfigProperty(
            "awsRetryMode",
            AWSClientRuntimeTypes.Core.AWSRetryMode,
            { it.format("\$N.retryMode()", AWSClientRuntimeTypes.Core.AWSClientConfigDefaultsProvider) },
            true
        ),
        ConfigProperty("maxAttempts", SwiftTypes.Int.toOptional())
    )
}
