//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

final public class AWSPredictionsPlugin: PredictionsCategoryPlugin {

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return "PredKey"
    }

    public func configure(using configuration: Any) throws {

    }

    init() {

    }

}
