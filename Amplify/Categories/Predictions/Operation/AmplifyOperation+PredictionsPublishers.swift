//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: - PredictionsIdentifyOperation

public extension AmplifyOperation
    where
    Request == PredictionsIdentifyOperation.Request,
    Success == PredictionsIdentifyOperation.Success,
    Failure == PredictionsIdentifyOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - PredictionsInterpretOperation

public extension AmplifyOperation
    where
    Request == PredictionsInterpretOperation.Request,
    Success == PredictionsInterpretOperation.Success,
    Failure == PredictionsInterpretOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - PredictionsSpeechToTextOperation

public extension AmplifyOperation
    where
    Request == PredictionsSpeechToTextOperation.Request,
    Success == PredictionsSpeechToTextOperation.Success,
    Failure == PredictionsSpeechToTextOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - PredictionsTextToSpeechOperation

public extension AmplifyOperation
    where
    Request == PredictionsTextToSpeechOperation.Request,
    Success == PredictionsTextToSpeechOperation.Success,
    Failure == PredictionsTextToSpeechOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - PredictionsTranslateTextOperation

public extension AmplifyOperation
    where
    Request == PredictionsTranslateTextOperation.Request,
    Success == PredictionsTranslateTextOperation.Success,
    Failure == PredictionsTranslateTextOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}
#endif
