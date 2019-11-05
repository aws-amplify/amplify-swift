//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify

class AWSRekognitionService: AWSRekognitionServiceBehaviour {

    var identifier: String!
    var rekognitionBehavior: AWSRekognitionBehavior!

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

        AWSRekognition.register(with: serviceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)

        let awsRekognitionAdapter = AWSRekognitionAdapter(awsRekognition)
        self.init(awsRekognition: awsRekognitionAdapter, identifier: identifier)
    }

    init(awsRekognition: AWSRekognitionBehavior,
         identifier: String) {
        self.rekognitionBehavior = awsRekognition
        self.identifier = identifier
    }

    func reset() {
        AWSRekognition.remove(forKey: identifier)
        rekognitionBehavior = nil
        identifier = nil
    }

    func getEscapeHatch() -> AWSRekognition {
        return rekognitionBehavior.getRekognition()
    }

    func detectLabels(image: CGImage,
                      onEvent: @escaping AWSRekognitionService.RekognitionServiceEventHandler) {

        let request = AWSRekognitionDetectLabelsRequest()
        let rekognitionImage = AWSRekognitionImage()

        let data = image.dataProvider?.data as Data?

        rekognitionImage?.bytes = data

        request?.image = rekognitionImage

        rekognitionBehavior.detectLabels(request: request!).continueWith { (task) -> Any? in
            guard task.error == nil else {
                // onEvent error
                return nil
            }

            guard let result = task.result else {
                // onEvent Error
                return nil
            }

            guard let labels = result.labels else {
                // missing labels, success or error?
                return nil
            }

            var newLabels = IdentifyLabelsResultUtils.process(labels)
            onEvent(.completed(IdentifyLabelsResult(labels: newLabels)))
            return nil
        }

    }
}
