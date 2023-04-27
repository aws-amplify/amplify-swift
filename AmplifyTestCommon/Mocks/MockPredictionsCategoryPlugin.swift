//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockPredictionsCategoryPlugin: MessageReporter, PredictionsCategoryPlugin {
    func identify<Output>(_ request: Predictions.Identify.Request<Output>, in image: URL, options: Predictions.Identify.Options?) async throws -> Output {
        fatalError()
    }

    func convert<Input, Options, Output>(_ request: Predictions.Convert.Request<Input, Options, Output>, options: Options?) async throws -> Output {
        fatalError()
    }

    func interpret(text: String, options: Predictions.Interpret.Options?) async throws -> Predictions.Interpret.Result {
        fatalError()
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() async {
        notify("reset")
    }

    var key: String {
        return "MockPredictionsCategoryPlugin"
    }
}

class MockSecondPredictionsCategoryPlugin: MockPredictionsCategoryPlugin {
    override var key: String {
        return "MockSecondPredictionsCategoryPlugin"
    }
}
