//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockPredictionsCategoryPlugin: MessageReporter, PredictionsCategoryPlugin, @unchecked Sendable {
    func identify<Output>(_ request: Predictions.Identify.Request<Output>, in image: URL, options: Predictions.Identify.Options?) async throws -> Output {
        fatalError()
    }

    func convert<Options, Output>(_ request: Predictions.Convert.Request<some Any, Options, Output>, options: Options?) async throws -> Output {
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

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondPredictionsCategoryPlugin: MockPredictionsCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondPredictionsCategoryPlugin"
    }
}
