//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPResponse
import protocol ClientRuntime.ServiceError
import protocol ClientRuntime.HTTPError

/// A protocol for a type that can be matched to an HTTP error response that does not match a modeled error.
///
/// When an error HTTP response is received and cannot be matched to a known / modeled error type, the SDK
/// should look at all of its `UnknownAWSHTTPErrorCandidate`s to see if one matches.  If so, an instance of
/// that candidate should be created and returned.
protocol UnknownAWSHTTPErrorCandidate: ServiceError, HTTPError, Error {

    /// The error code for the error.
    ///
    /// If a HTTP response matches this error type, then an instance of this error should be created.
    static var errorCode: String { get }

    init(httpResponse: HTTPResponse, message: String?, requestID: String?, requestID2: String?)
}

// These extensions provide for conformance with the `ServiceError` and
// `AWSServiceError` types.
extension UnknownAWSHTTPErrorCandidate {

    /// The type name for this error.
    public var typeName: String? { Self.errorCode }
}
