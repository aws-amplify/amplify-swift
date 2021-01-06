//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsTranslateTextRequest: AmplifyOperationRequest {

    /// The text to translate.
    public let textToTranslate: String

    /// The language to translate
    public let targetLanguage: LanguageType?

    /// Source language of the text given.
    public let language: LanguageType?

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

    public init(textToTranslate: String,
                targetLanguage: LanguageType?,
                language: LanguageType?,
                options: Options) {
        self.textToTranslate = textToTranslate
        self.language = language
        self.targetLanguage = targetLanguage
        self.options = options
    }
}

extension PredictionsTranslateTextRequest {
    public struct Options {

        /// The default NetworkPolicy for the operation. The default value will be `auto`.
        public let defaultNetworkPolicy: DefaultNetworkPolicy

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                    pluginOptions: Any? = nil) {
            self.defaultNetworkPolicy = defaultNetworkPolicy
            self.pluginOptions = pluginOptions
        }
    }
}
