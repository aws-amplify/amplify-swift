//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: APICategoryAuthProviderBehavior {
    public func apiAuthProviders() -> APIAuthProviders? {
        return plugin.apiAuthProviders()
    }
}
