//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.BaseError
import enum ClientRuntime.BaseErrorDecodeError
import class SmithyHTTPAPI.HTTPResponse
@_spi(SmithyReadWrite) import class SmithyXML.Reader

public struct EC2QueryError: BaseError {
    public let code: String
    public let message: String?
    public let requestID: String?
    @_spi(SmithyReadWrite) public let errorBodyReader: Reader

    public let httpResponse: HTTPResponse
    @_spi(SmithyReadWrite) public let responseReader: Reader

    @_spi(SmithyReadWrite)
    public init(httpResponse: HTTPResponse, responseReader: Reader, noErrorWrapping: Bool) throws {
        self.httpResponse = httpResponse
        self.responseReader = responseReader
        self.errorBodyReader = responseReader["Errors"]["Error"]
        let code: String? = try errorBodyReader["Code"].readIfPresent()
        guard let code else { throw BaseErrorDecodeError.missingRequiredData }
        let message: String? = try errorBodyReader["Message"].readIfPresent()
        let requestID: String? = try responseReader["RequestId"].readIfPresent()
                                 ?? responseReader["RequestID"].readIfPresent()
        self.code = code
        self.message = message
        self.requestID = requestID
    }
}
