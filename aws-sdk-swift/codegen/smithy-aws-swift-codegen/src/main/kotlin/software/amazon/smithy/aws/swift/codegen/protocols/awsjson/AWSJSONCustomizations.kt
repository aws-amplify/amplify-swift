/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.awsjson

import software.amazon.smithy.aws.swift.codegen.AWSHTTPProtocolCustomizations
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.traits.TimestampFormatTrait

class AWSJSONCustomizations : AWSHTTPProtocolCustomizations() {
    override val baseErrorSymbol: Symbol = AWSClientRuntimeTypes.AWSJSON.AWSJSONError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.EPOCH_SECONDS
}
