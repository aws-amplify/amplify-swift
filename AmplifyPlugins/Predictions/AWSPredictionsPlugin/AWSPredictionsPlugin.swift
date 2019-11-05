//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSPredictionsPlugin: PredictionsCategoryPlugin {

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// An instance of the translate service
    var translateService: AWSTranslateServiceBehaviour!

    var rekognitionService: AWSRekognitionServiceBehaviour!

    var authService: AWSAuthServiceBehavior!

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return PluginConstants.awsPredictionsPluginKey
    }

    public init() {
    }
}
