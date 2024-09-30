/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.awsjson

import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.protocols.core.StaticHttpBindingResolver

class AWSJSONHttpBindingResolver(
    context: ProtocolGenerator.GenerationContext,
    defaultContentType: String
) : StaticHttpBindingResolver(context, awsJsonHttpTrait, defaultContentType) {

    companion object {
        private val awsJsonHttpTrait: HttpTrait = HttpTrait
            .builder()
            .code(200)
            .method("POST")
            .uri(UriPattern.parse("/"))
            .build()
    }
}
