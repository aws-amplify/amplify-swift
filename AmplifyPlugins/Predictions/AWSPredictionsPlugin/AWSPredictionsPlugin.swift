//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

final public class AWSPredictionsPlugin: PredictionsCategoryPlugin {
    let awsPredictionsPluginKey = "awsPredictionsPlugin"

    /// An instance of the predictions  service
    var predictionsService: AWSPredictionsService!
    var coreMLService: CoreMLPredictionBehavior?
    var authService: AWSAuthServiceBehavior!
    var config: PredictionsPluginConfiguration!

    /// public limit rekognition has on number of faces it can detect.
    public static let rekognitionMaxEntitiesLimit = 50

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return awsPredictionsPluginKey
    }

    public func getEscapeHatch<T>(key: PredictionsAWSService<T>) -> T {
        predictionsService.getEscapeHatch(client: key)
    }

    public init() {}
}

extension AWSPredictionsPlugin: AmplifyVersionable { }
