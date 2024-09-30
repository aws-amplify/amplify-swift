/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.protocols.awsquery.AWSQueryProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.protocols.ec2query.EC2QueryProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.protocols.restxml.RestXMLProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

/**
 * Integration that registers protocol generators this package provides
 */
class AddProtocols : SwiftIntegration {
    /**
     * Gets the sort order of the customization from -128 to 127, with lowest
     * executed first.
     *
     * @return Returns the sort order, defaults to -10.
     */
    override val order: Byte = -10

    override val protocolGenerators: List<ProtocolGenerator> = listOf(
        AWSRestJson1ProtocolGenerator(),
        AWSJSON1_0ProtocolGenerator(),
        AWSJSON1_1ProtocolGenerator(),
        RestXMLProtocolGenerator(),
        AWSQueryProtocolGenerator(),
        EC2QueryProtocolGenerator()
    )
}
