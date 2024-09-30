/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import protocol ClientRuntime.ServiceError
import protocol ClientRuntime.ModeledError

/// Provides properties for an error returned by an AWS service.
public protocol AWSServiceError: ServiceError {

    /// The error code for this error, if known.
    ///
    /// The location of the error code within the response is defined on the Smithy protocol in use.
    var errorCode: String? { get }

    /// The Request ID for a request made to an AWS service, if available.
    var requestID: String? { get }
}

extension AWSServiceError {

    /// Provides the modeled error's type name as a instance property.
    ///
    /// Provided to allow for conformance with `AWSServiceError`.
    public var errorCode: String? { typeName }
}
