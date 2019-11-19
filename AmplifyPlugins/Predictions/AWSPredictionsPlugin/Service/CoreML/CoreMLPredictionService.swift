//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreMLPredictionsPlugin

class CoreMLPredictionService: CoreMLPredictionBehavior {

    let coreMLPlugin: CoreMLPredictionsPlugin

    init(config: Any) throws {
        self.coreMLPlugin = CoreMLPredictionsPlugin()
        try coreMLPlugin.configure(using: config)
    }

    func comprehend(text: String, onEvent: @escaping InterpretTextEventHandler) {
        _ = coreMLPlugin.interpret(text: text,
                                   options: PredictionsInterpretRequest.Options()) { event in
                                    switch event {
                                    case .completed(let result):
                                        onEvent(.completed(result))
                                    case .failed(let error):
                                        onEvent(.failed(error))
                                    default:
                                        break
                                    }
        }
    }

    func identify(_ imageURL: URL,
                  type: IdentifyAction,
                  onEvent: @escaping IdentifyEventHandler) {
        _ = coreMLPlugin.identify(type: type,
                                  image: imageURL,
                                  options: PredictionsIdentifyRequest.Options()) { event in
                                    switch event {
                                    case .completed(let result):
                                        onEvent(.completed(result))
                                    case .failed(let error):
                                        onEvent(.failed(error))
                                    default:
                                        break
                                    }
        }
    }
}
