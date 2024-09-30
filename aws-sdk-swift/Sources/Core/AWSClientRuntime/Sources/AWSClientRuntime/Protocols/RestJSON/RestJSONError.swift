//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.BaseError
import enum ClientRuntime.BaseErrorDecodeError
import class SmithyHTTPAPI.HTTPResponse
@_spi(SmithyReadWrite) import class SmithyJSON.Reader

public struct RestJSONError: BaseError {
    public let code: String
    public let message: String?
    public let requestID: String?

    public let httpResponse: HTTPResponse
    private let responseReader: Reader
    @_spi(SmithyReadWrite) public var errorBodyReader: Reader { responseReader }

    // header identifying the error code
    let X_AMZN_ERROR_TYPE_HEADER_NAME = "X-Amzn-Errortype"

    // returned by RESTFUL services that do no send a payload (like in a HEAD request)
    let X_AMZN_ERROR_MESSAGE_HEADER_NAME = "x-amzn-error-message"

    // returned by some services like Cognito
    let X_AMZN_ERRORMESSAGE_HEADER_NAME = "x-amzn-ErrorMessage"

    // error message header returned by event stream errors
    let X_AMZN_EVENT_ERROR_MESSAGE_HEADER_NAME = ":error-message"

    @_spi(SmithyReadWrite)
    public init(httpResponse: HTTPResponse, responseReader: SmithyJSON.Reader, noErrorWrapping: Bool) throws {
        let type = try httpResponse.headers.value(for: X_AMZN_ERROR_TYPE_HEADER_NAME)
                   ?? responseReader["code"].readIfPresent()
                   ?? responseReader["__type"].readIfPresent()

        guard let type else { throw BaseErrorDecodeError.missingRequiredData }

        // this is broken into steps since the Swift compiler can't type check a compound statement
        // in reasonable time
        var message = httpResponse.headers.value(for: X_AMZN_ERROR_MESSAGE_HEADER_NAME)
        message = message ?? httpResponse.headers.value(for: X_AMZN_EVENT_ERROR_MESSAGE_HEADER_NAME)
        message = message ?? httpResponse.headers.value(for: X_AMZN_ERRORMESSAGE_HEADER_NAME)
        message = try message ?? responseReader["message"].readIfPresent()
        message = try message ?? responseReader["Message"].readIfPresent()
        message = try message ?? responseReader["errorMessage"].readIfPresent()

        self.code = sanitizeErrorType(type)
        self.message = message
        self.requestID = httpResponse.requestID
        self.httpResponse = httpResponse
        self.responseReader = responseReader
    }
}

/// Filter additional information from error name and sanitize it
/// Reference: https://awslabs.github.io/smithy/1.0/spec/aws/aws-restjson1-protocol.html#operation-error-serialization
func sanitizeErrorType(_ type: String) -> String {
    return type.substringAfter("#").substringBefore(":").trim()
}
