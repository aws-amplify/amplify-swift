//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

protocol UserPoolAnalyticsBehavior {

    func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
}
