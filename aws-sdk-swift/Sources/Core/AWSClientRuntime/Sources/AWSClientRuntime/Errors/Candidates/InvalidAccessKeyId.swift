//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPResponse
import protocol ClientRuntime.HTTPError

/// An error that may be returned by AWS when the access key used cannot be found by the server.
///
/// Typical message: "The AWS Access Key Id you provided does not exist in our records."
public struct InvalidAccessKeyId: AWSServiceError, HTTPError, Error {

    static var errorCode: String { "InvalidAccessKeyId" }
    public var httpResponse: HTTPResponse
    public var requestID: String?
    public var requestID2: String?
    public var message: String?

    init(httpResponse: HTTPResponse, message: String?, requestID: String?, requestID2: String?) {
        self.httpResponse = httpResponse
        self.message = message
        self.requestID = requestID
        self.requestID2 = requestID2
    }
}

extension InvalidAccessKeyId: UnknownAWSHTTPErrorCandidate {}
