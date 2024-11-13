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

public struct AWSJSONError: BaseError {
    public let code: String
    public let message: String?
    public let requestID: String?
    @_spi(SmithyReadWrite) public var errorBodyReader: Reader { responseReader }

    public let httpResponse: HTTPResponse
    private let responseReader: Reader

    @_spi(SmithyReadWrite)
    public init(httpResponse: HTTPResponse, responseReader: Reader, noErrorWrapping: Bool, code: String? = nil) throws {
        let errorCode: String? = try httpResponse.headers.value(for: "X-Amzn-Errortype")
                            ?? responseReader["code"].readIfPresent()
                            ?? responseReader["__type"].readIfPresent()
        let resolvedCode = code ?? errorCode
        let message: String? = try responseReader["Message"].readIfPresent()
        let requestID: String? = try responseReader["RequestId"].readIfPresent()
        guard let resolvedCode else { throw BaseErrorDecodeError.missingRequiredData }
        self.code = sanitizeErrorType(resolvedCode)
        self.message = message
        self.requestID = requestID
        self.httpResponse = httpResponse
        self.responseReader = responseReader
    }
}

extension AWSJSONError {
    @_spi(SmithyReadWrite)
    public static func makeQueryCompatibleAWSJsonError(
        httpResponse: HTTPResponse,
        responseReader: Reader,
        noErrorWrapping: Bool,
        errorDetails: String?
    ) throws -> AWSJSONError {
        let errorCode = try AwsQueryCompatibleErrorDetails.parse(errorDetails).code
        return try AWSJSONError(
            httpResponse: httpResponse,
            responseReader: responseReader,
            noErrorWrapping: noErrorWrapping,
            code: errorCode
        )
    }
}
