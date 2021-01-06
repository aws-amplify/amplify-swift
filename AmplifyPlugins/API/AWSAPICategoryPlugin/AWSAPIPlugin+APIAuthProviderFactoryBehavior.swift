//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSAPIPlugin {
    public func apiAuthProviderFactory() -> APIAuthProviderFactory {
        return authProviderFactory
    }
}
