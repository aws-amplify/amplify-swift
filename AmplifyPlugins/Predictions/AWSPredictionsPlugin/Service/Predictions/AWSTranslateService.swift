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
                       language: LanguageType,
                       targetLanguage: LanguageType,
                       onEvent: @escaping AWSTranslateService.TranslateTextServiceEventHandler) {
        let request = AWSTranslateTranslateTextRequest()
        request?.sourceLanguageCode = "en"
        request?.targetLanguageCode = "it"
        request?.text = text
        translateBehavior.translateText(request: request!).continueWith { (task) -> Any? in
            if let result = task.result?.translatedText {
                print(result)
                onEvent(.completed(TranslateTextResult(text: (task.result?.translatedText!)!, targetLanguage: .italian)))
            } else {
                print(task.error)
            }


            return nil
        }

    }
}
