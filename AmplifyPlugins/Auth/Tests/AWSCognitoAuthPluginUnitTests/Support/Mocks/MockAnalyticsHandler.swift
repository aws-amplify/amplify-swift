//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

struct MockAnalyticsHandler: UserPoolAnalyticsBehavior {

    func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
        return nil
    }

}
