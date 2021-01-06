//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol APICategoryAuthProviderFactoryBehavior {
    func apiAuthProviderFactory() -> APIAuthProviderFactory
}
