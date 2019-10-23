//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsConvertRequest: AmplifyOperationRequest {

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

    public init(options: Options) {
        self.options = options
    }
}

public extension PredictionsConvertRequest {

    struct Options {
        
    }
}
