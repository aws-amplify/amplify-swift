//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension CoreMLPredictionsPlugin {

    public func configure(using configuration: Any) throws {
        guard configuration is JSONValue else {
            let errorDesciption = CoreMLPluginErrorConstants.decodeConfigurationError.errorDescription
            let recoverySuggestion = CoreMLPluginErrorConstants.decodeConfigurationError.recoverySuggestion
            throw PluginError.pluginConfigurationError(errorDesciption, recoverySuggestion)
        }
        configure(naturalLanguageBehavior: CoreMLNaturalLanguageAdaptor())
    }

    func configure(naturalLanguageBehavior: CoreMLNaturalLanguageBehavior,
                   queue: OperationQueue = OperationQueue()) {
        coreMLNaturalLanguage = naturalLanguageBehavior
        self.queue = queue
    }
}
