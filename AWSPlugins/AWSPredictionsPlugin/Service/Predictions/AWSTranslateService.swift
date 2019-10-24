//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate
import Amplify

class AWSTranslateService: AWSTranslateServiceBehaviour {

    var identifier: String!
    var translateBehavior: AWSTranslateBehavior!

    convenience init(region: AWSRegionType,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                     identifier: String) throws {
        let serviceConfigurationOptional = AWSServiceConfiguration(region: region,
                                                                   credentialsProvider: cognitoCredentialsProvider)

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.serviceConfigurationInitializationError.errorDescription,
                PluginErrorConstants.serviceConfigurationInitializationError.recoverySuggestion)
        }

        AWSTranslate.register(with: serviceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)

        let awsTranslateAdapter = AWSTranslateAdapter(awsTranslate)
        self.init(awsTranslate: awsTranslateAdapter, identifier: identifier)
    }

    init(awsTranslate: AWSTranslateBehavior,
         identifier: String) {
        self.translateBehavior = awsTranslate
        self.identifier = identifier
    }

    func reset() {
        AWSTranslate.remove(forKey: identifier)
        translateBehavior = nil
        identifier = nil
    }

    func getEscapeHatch() -> AWSTranslate {
        return translateBehavior.getTranslate()
    }

    func translateText(text: String,
                       onEvent: @escaping TranslateServiceTranslateTextEventHandler) {

    }
}
