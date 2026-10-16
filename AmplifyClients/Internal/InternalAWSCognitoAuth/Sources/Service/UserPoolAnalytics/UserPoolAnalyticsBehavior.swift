//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package protocol UserPoolAnalyticsBehavior {

    /// The Pinpoint analytics metadata to send with a user pool request, or `nil` for none.
    ///
    /// `async` so that a host can resolve it with I/O on first use (the Cognito client reads the Pinpoint
    /// endpoint ID from the keychain lazily). A synchronous implementation, such as the plugin's
    /// `UserPoolAnalytics`, satisfies it unchanged. Every caller is already `async`.
    func analyticsMetadata() async -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
}
