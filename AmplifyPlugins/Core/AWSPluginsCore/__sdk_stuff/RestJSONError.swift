//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct RestJSONErrorPayload: Decodable {
    // TODO: Use a custom decoder here
    let code: String?
    let __type: String?

    let message: String?
    let Message: String?
    let errorMessage: String?

    public init(
        code: String?,
        __type: String?,
        message: String?,
        Message: String?,
        errorMessage: String?
    ) {
        self.code = code
        self.__type = __type
        self.message = message
        self.Message = Message
        self.errorMessage = errorMessage
    }

    public var resolvedErrorType: String? {
        code ?? __type
    }

    public var resolvedErrorMessage: String? {
        message ?? Message ?? errorMessage
    }
}

public struct RestJSONError {
    public let message: String?
    public let type: String?

    public init(data: Data, response: HTTPURLResponse) throws {
        let errorMessage = response.value(
            forHTTPHeaderField: "x-amzn-error-message"
        ) ?? response.value(
            forHTTPHeaderField: ":error-message"
        ) ?? response.value(
            forHTTPHeaderField: "x-amzn-ErrorMessage"
        )

        let errorType = response.value(
            forHTTPHeaderField: "X-Amzn-Errortype"
        )

        let errorPayload = try JSONDecoder().decode(
            RestJSONErrorPayload.self,
            from: data
        )

        self.message = (errorMessage ?? errorPayload.resolvedErrorMessage)
            .map { $0.substringAfter("#").substringBefore(":").trim() }
        self.type = errorType ?? errorPayload.resolvedErrorType
    }
}
