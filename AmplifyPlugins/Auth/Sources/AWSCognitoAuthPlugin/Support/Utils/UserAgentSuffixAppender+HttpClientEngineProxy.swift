//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalHttpEngineProxy) @_spi(InternalAmplifyPluginExtension) import InternalAmplifyCredentials
import InternalAWSCognitoAuth

// Declared here rather than next to `HttpClientEngineProxy` in `InternalAWSCognitoAuth`, so that the
// engine does not depend on `InternalAmplifyCredentials`.
extension UserAgentSuffixAppender: HttpClientEngineProxy {}
