//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsTranslateTextRequest: AmplifyOperationRequest, PredictionsConvertRequest {

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

    public let textToTranslate: String
    
    public let targetLanguage: LanguageType
    
    public let language: LanguageType

    public init(textToTranslate: String,
                targetLanguage: LanguageType,
                language: LanguageType,
                options: Options) {
        self.textToTranslate = textToTranslate
        self.language = language
        self.targetLanguage = targetLanguage
        self.options = options
    }
}

public extension PredictionsTranslateTextRequest {
    
    struct Options {
        public let callType: CallType
        public init(callType: CallType = .auto) {
            self.callType = callType
        }
    }
}
