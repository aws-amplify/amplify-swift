/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class SmithyHTTPAPI.HTTPResponse
import ClientRuntime

/// AWS specific Service Error structure used when exact error could not be deduced from the `HTTPResponse`
/// Developers should catch unknown errors by the interface `AWSServiceError`, then use the `errorCode` to determine & handle each type of error.
@_spi(UnknownAWSHTTPServiceError) public struct UnknownAWSHTTPServiceError: AWSServiceError, HTTPError, Error {

    public var errorCode: String? { typeName }

    /// The error type name for this error, or `nil` if the type is not known.
    public var typeName: String?

    public var message: String?

    public var requestID: String?

    public var requestID2: String?

    public var httpResponse: HTTPResponse
}

extension UnknownAWSHTTPServiceError {

    /// Creates an `UnknownAWSHttpServiceError` from a `HTTPResponse` and associated parameters.
    /// - Parameters:
    ///   - httpResponse: The `HTTPResponse` for this error.
    ///   - message: The message associated with this error.
    ///   - requestID: The request ID associated with this error.
    ///   - requestID2: The request ID2 associated with this error (defined on S3 only.)  Defaults to `nil`.
    ///   - typeName: The non-namespaced name of the error type for this error.
    public init(
        httpResponse: HTTPResponse,
        message: String?,
        requestID: String?,
        requestID2: String? = nil,
        typeName: String?
    ) {
        self.typeName = typeName
        self.message = message
        self.requestID = requestID ?? httpResponse.requestID
        self.requestID2 = requestID2
        self.httpResponse = httpResponse
    }
}

extension UnknownAWSHTTPServiceError {

    /// Returns an appropriate error object to represent a HTTP response that could not be matched to a known error type.
    ///
    /// May return an instance of `UnknownAWSHTTPServiceError` or another error type.
    /// - Parameters:
    ///   - httpResponse: The HTTP/HTTPS response for the error
    ///   - message: The message associated with this error, or `nil`.
    ///   - requestID: The request ID associated with this error, or `nil`.
    ///   - requestID2: The request ID2 associated with this error (ID2 used on S3 only.)  Defaults to `nil`.
    ///   - typeName: The non-namespaced name of the error type for this error, or `nil`.
    /// - Returns: An error that represents the response.
    public static func makeError<Base: BaseError>(
        baseError: Base
    ) throws -> Error {
        let candidates: [UnknownAWSHTTPErrorCandidate.Type] = [
            InvalidAccessKeyId.self
        ]
        if let Candidate = candidates.first(where: { $0.errorCode == baseError.code }) {
            return Candidate.init(
                httpResponse: baseError.httpResponse,
                message: baseError.message,
                requestID: baseError.requestID,
                requestID2: baseError.requestID2
            )
        }
        return UnknownAWSHTTPServiceError(
            httpResponse: baseError.httpResponse,
            message: baseError.message,
            requestID: baseError.requestID,
            requestID2: baseError.requestID2,
            typeName: baseError.code
        )
    }
}

extension ClientRuntime.BaseError {

    var requestID2: String? { nil }
}
