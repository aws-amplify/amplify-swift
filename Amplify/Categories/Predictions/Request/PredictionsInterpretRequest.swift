//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsInterpretRequest: AmplifyOperationRequest {

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

    public let textToInterpret: String

    public init(textToInterpret: String,
                options: Options) {
        self.textToInterpret = textToInterpret
        self.options = options
    }
}

public extension PredictionsInterpretRequest {

    struct Options {
        public let callType: CallType
        public init(callType: CallType = .auto) {
            self.callType = callType
        }
    }
}
