//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class PredictionsConvertRequest: AmplifyOperationRequest {
    
    public let options: Options
    
    public var type: ConvertAction
    
    public init(type: ConvertAction, options:Options) {
        self.type = type
        self.options = options
    }
}

extension PredictionsConvertRequest {
    public class Options {

            /// The default NetworkPolicy for the operation. The default value will be `auto`.
            public let defaultNetworkPolicy: DefaultNetworkPolicy
        
            ///the voice type selected for synthesizing text to speech
            public let voiceType: VoiceType?

            /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
            /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
            /// key/values
            public let pluginOptions: Any?

            public init(defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                        voiceType: VoiceType? = nil,
                        pluginOptions: Any? = nil) {
                self.defaultNetworkPolicy = defaultNetworkPolicy
                self.pluginOptions = pluginOptions
                self.voiceType = voiceType
            }
    }
}
