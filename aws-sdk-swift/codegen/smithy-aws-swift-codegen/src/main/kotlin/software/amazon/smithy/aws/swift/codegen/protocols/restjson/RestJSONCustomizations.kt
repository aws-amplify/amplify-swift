/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.restjson

import software.amazon.smithy.aws.swift.codegen.AWSHTTPProtocolCustomizations
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol

class RestJSONCustomizations : AWSHTTPProtocolCustomizations() {

    override val baseErrorSymbol: Symbol = AWSClientRuntimeTypes.RestJSON.RestJSONError
}
