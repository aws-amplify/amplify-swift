//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

// MARK: - PredictionsIdentifyOperation

// The overrides require a feature and bugfix introduced in Swift 5.2
#if swift(>=5.2)

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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
