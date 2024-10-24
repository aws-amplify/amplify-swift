//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

protocol UserPoolAnalyticsBehavior {

    func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
}
