//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

struct MockAnalyticsHandler: UserPoolAnalyticsBehavior {

    func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
        return nil
    }

}
