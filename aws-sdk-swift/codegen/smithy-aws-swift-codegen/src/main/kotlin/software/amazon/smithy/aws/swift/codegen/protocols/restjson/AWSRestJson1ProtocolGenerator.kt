/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.aws.swift.codegen.protocols.restjson

import software.amazon.smithy.aws.swift.codegen.AWSHTTPBindingProtocolGenerator
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.shapes.ShapeId

class AWSRestJson1ProtocolGenerator : AWSHTTPBindingProtocolGenerator(RestJSONCustomizations()) {
    override val defaultContentType = "application/json"
    override val protocol: ShapeId = RestJson1Trait.ID
    override val testsToIgnore = setOf(
        "SDKAppliedContentEncoding_restJson1",
        "SDKAppendedGzipAfterProvidedEncoding_restJson1",
    )
}
