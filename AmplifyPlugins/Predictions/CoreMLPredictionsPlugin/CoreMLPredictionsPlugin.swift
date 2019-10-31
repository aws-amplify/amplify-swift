//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class CoreMLPredictionsPlugin: PredictionsCategoryPlugin {


    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return PluginConstants.coreMLPluginsKey
    }

    public init() {
    }
}
