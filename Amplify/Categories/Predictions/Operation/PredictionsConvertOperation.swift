//
//  PredictionsConvertOperation.swift
//  Amplify
//
//  Created by Stone, Nicki on 1/13/20.
//

import Foundation

public protocol PredictionsConvertOperation: AmplifyOperation<
    PredictionsConvertRequest,
    Void,
    ConvertResult,
PredictionsError> { }

public extension HubPayload.EventName.Predictions {
    static let convert = "Predictions.convert"
}
