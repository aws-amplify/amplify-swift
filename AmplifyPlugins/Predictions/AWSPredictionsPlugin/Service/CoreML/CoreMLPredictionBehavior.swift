//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol CoreMLPredictionBehavior: class {

    typealias InterpretTextEventHandler = (InterpretEvent) -> Void
    typealias InterpretEvent = PredictionsEvent<InterpretResult, PredictionsError>

    func comprehend(text: String,
                    onEvent: @escaping InterpretTextEventHandler)
}
