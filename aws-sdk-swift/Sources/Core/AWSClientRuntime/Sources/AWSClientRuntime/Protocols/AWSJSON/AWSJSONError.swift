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
    public init(httpResponse: HTTPResponse, responseReader: Reader, noErrorWrapping: Bool) throws {
        let code: String? = try httpResponse.headers.value(for: "X-Amzn-Errortype")
                            ?? responseReader["code"].readIfPresent()
                            ?? responseReader["__type"].readIfPresent()
        let message: String? = try responseReader["Message"].readIfPresent()
        let requestID: String? = try responseReader["RequestId"].readIfPresent()
        guard let code else { throw BaseErrorDecodeError.missingRequiredData }
        self.code = sanitizeErrorType(code)
        self.message = message
        self.requestID = requestID
        self.httpResponse = httpResponse
        self.responseReader = responseReader
    }
}
