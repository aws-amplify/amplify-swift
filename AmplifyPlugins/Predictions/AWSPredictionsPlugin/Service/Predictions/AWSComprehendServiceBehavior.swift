//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol AWSComprehendServiceBehavior {

//    typealias ComprehendServiceEventHandler = (ComprehendServiceEvent) -> Void
//    typealias ComprehendServiceEvent = PredictionsEvent<InterpretResult, PredictionsError>

    func comprehend(text: String) async throws -> Predictions.Interpret.Result
}
