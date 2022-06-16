//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

struct UpdateAttributesOperationHelper {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    static func update(
        attributes: [AuthUserAttribute],
        accessToken: String,
        userPoolFactory: @escaping CognitoUserPoolFactory,
        clientMetaData: [String: String]) async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
            
            let userPoolService = try userPoolFactory()
            
            let input = UpdateUserAttributesInput(accessToken: accessToken,
                                                  clientMetadata: clientMetaData,
                                                  userAttributes: attributes.map({ $0.sdkClientAttributeType() }))
            
            let result = try await userPoolService.updateUserAttributes(input: input)
            
            guard let codeDeliveryDetailsList = result.codeDeliveryDetailsList else {
                let authError = AuthError.service("Unable to get Auth code delivery details",
                                                  AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                                                  nil)
                throw authError
            }
            
            var finalResult = [AuthUserAttributeKey: AuthUpdateAttributeResult]()
            for item in codeDeliveryDetailsList {
                if let attribute = item.attributeName {
                    let authCodeDeliveryDetails = item.toAuthCodeDeliveryDetails()
                    let nextStep = AuthUpdateAttributeStep.confirmAttributeWithCode(authCodeDeliveryDetails, nil)
                    let updateAttributeResult = AuthUpdateAttributeResult(isUpdated: false,
                                                                          nextStep: nextStep)
                    finalResult[AuthUserAttributeKey(rawValue: attribute)] = updateAttributeResult
                }
            }
            
            // Check if all items are added to the dictionary
            for item in attributes where finalResult[item.key] == nil {
                let updateAttributeResult = AuthUpdateAttributeResult(isUpdated: true, nextStep: .done)
                finalResult[item.key] = updateAttributeResult
            }
            
            return finalResult
        }
    
}
