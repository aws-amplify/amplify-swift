//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsSpeechToTextRequest: AmplifyOperationRequest {

    /// The text to synthesize to speech
    public let speechToText: URL

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

    public init(speechToText: URL,
                options: Options) {
        self.speechToText = speechToText
        self.options = options
    }
}

extension PredictionsSpeechToTextRequest {
    public struct Options {

            /// The default NetworkPolicy for the operation. The default value will be `auto`.
            public let defaultNetworkPolicy: DefaultNetworkPolicy

            /// The language of the audio file you are transcribing
            public let language: LanguageType?

            /// Extra plugin specific options, only used in special circumstances when the existing options do not
            /// provide a way to utilize the underlying storage system's functionality. See plugin documentation for
            /// expected key/values
            public let pluginOptions: Any?

            public init(defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                        language: LanguageType? = nil,
                        pluginOptions: Any? = nil) {
                self.defaultNetworkPolicy = defaultNetworkPolicy
                self.language = language
                self.pluginOptions = pluginOptions
            }
    }
}
