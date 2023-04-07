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

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// An instance of the predictions  service
     /*
    var predictionsService: AWSPredictionsService!

    var coreMLService: CoreMLPredictionBehavior!

    var authService: AWSAuthServiceBehavior!

    var config: PredictionsPluginConfiguration!
     */

    /// public limit rekognition has on number of faces it can detect.
    public static let rekognitionMaxEntitiesLimit = 50

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return awsPredictionsPluginKey
    }

    /*
    public func getEscapeHatch(key: PredictionsAWSService) -> AWSService {
        return predictionsService.getEscapeHatch(key: key)
    }
     */

    init() {}
}

extension AWSPredictionsPlugin: AmplifyVersionable { }
