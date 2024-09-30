/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.swift.codegen.config.AWSDefaultClientConfiguration
import software.amazon.smithy.aws.swift.codegen.config.AWSEndpointClientConfiguration
import software.amazon.smithy.aws.swift.codegen.config.AWSRegionClientConfiguration
import software.amazon.smithy.aws.swift.codegen.plugins.AuthSchemePlugin
import software.amazon.smithy.aws.swift.codegen.plugins.DefaultAWSAuthSchemePlugin
import software.amazon.smithy.aws.swift.codegen.plugins.EndpointPlugin
import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.plugins.DefaultAWSClientPlugin

class AWSClientConfigurationIntegration : SwiftIntegration {
    override fun clientConfigurations(ctx: ProtocolGenerator.GenerationContext): List<ClientConfiguration> {
        return listOf(AWSDefaultClientConfiguration(), AWSRegionClientConfiguration(), AWSEndpointClientConfiguration(ctx))
    }

    override fun plugins(serviceConfig: ServiceConfig): List<Plugin> {
        return listOf(DefaultAWSClientPlugin(), EndpointPlugin(serviceConfig), DefaultAWSAuthSchemePlugin(serviceConfig), AuthSchemePlugin(serviceConfig))
    }
}
