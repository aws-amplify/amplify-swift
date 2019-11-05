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

        var data = image.dataProvider?.data as Data?

        rekognitionImage?.bytes = data

        request?.image = rekognitionImage

        rekognitionBehavior.detectLabels(request: request!).continueWith { (task) -> Any? in
            if let result = task.result?.labels {
                print(result)
                //create result object from response
                var labels = [Label]()
                for label in result {

                    var parents = [Parent]()
                    if let unwrappedParents = label.parents {
                        for parent in unwrappedParents {
                            if let name = parent.name {
                                parents.append(Parent(name: name))
                            }
                        }
                    }

                    let metadata = LabelMetadata(confidence: Double(truncating: label.confidence ?? 0.0), parents: parents)

                    var boundingBoxes = [BoundingBox]()
                    if let instances = label.instances {
                        for instance in instances {
                            guard let height = instance.boundingBox?.height,
                                let left = instance.boundingBox?.left,
                                let top = instance.boundingBox?.top,
                                let width = instance.boundingBox?.width else {
                                    continue
                            }
                            let boundingBox = BoundingBox(
                                height: Double(truncating: height),
                                left: Double(truncating: left),
                                top: Double(truncating: top),
                                width: Double(truncating: width))
                            boundingBoxes.append(boundingBox)
                        }
                    }
                    let newLabel = Label(name: label.name!, metadata: metadata, boundingBoxes: boundingBoxes)
                    labels.append(newLabel)

                }
                onEvent(.completed(IdentifyLabelsResult(labels: labels)))
            } else {
                print(task.error!)
            }

            return nil
        }

    }
}
