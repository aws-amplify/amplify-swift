//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSTranslate

protocol AWSTranslateServiceBehaviour {

    typealias TranslateServiceTranslateTextEventHandler = (TranslateServiceTranslateTextEvent) -> Void
    typealias TranslateServiceTranslateTextEvent = PredictionsEvent<String, PredictionsError>

    func reset()

    func getEscapeHatch() -> AWSTranslate

    func translateText(text: String,
                       onEvent: @escaping TranslateServiceTranslateTextEventHandler)
}
