//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider

// The AWS SDK clients are the production implementations of the engine's service protocols. The
// conformances live next to the protocols, in the engine, so that every consumer of the engine (the
// plugin and the Cognito client) shares one declaration rather than each declaring its own,
// which would be a duplicate conformance.

extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {}

extension CognitoIdentityClient: CognitoIdentityBehavior {}
