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

public struct RestXMLError: BaseError {
    public let code: String
    public let message: String?
    public let requestID: String?
    public var requestID2: String? { httpResponse.requestID2 }

    public let httpResponse: HTTPResponse
    private let responseReader: Reader
    @_spi(SmithyReadWrite) public let errorBodyReader: Reader

    @_spi(SmithyReadWrite)
    public init(httpResponse: HTTPResponse, responseReader: Reader, noErrorWrapping: Bool) throws {
        self.errorBodyReader = Self.errorBodyReader(responseReader: responseReader, noErrorWrapping: noErrorWrapping)
        let code: String? = try errorBodyReader["Code"].readIfPresent()
        if code == nil && httpResponse.statusCode != .notFound { throw BaseErrorDecodeError.missingRequiredData }
        let message: String? = try errorBodyReader["Message"].readIfPresent()
        let requestID: String? = try responseReader["RequestId"].readIfPresent() ?? httpResponse.requestID
        self.code = code ?? "NotFound"
        self.message = message
        self.requestID = requestID
        self.httpResponse = httpResponse
        self.responseReader = responseReader
    }

    private static func errorBodyReader(responseReader: Reader, noErrorWrapping: Bool) -> Reader {
        noErrorWrapping ? responseReader : responseReader["Error"]
    }
}
