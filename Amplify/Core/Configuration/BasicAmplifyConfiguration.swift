//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A basic struct containing Amplify configurations. In addition to this being the value into which default
/// configurations from `amplifyconfiguration.json` are read, this structure can also be used to override global
/// configurations at runtime.
public struct BasicAmplifyConfiguration: AmplifyConfiguration {
    public let analytics: CategoryConfiguration?
    public let api: CategoryConfiguration?
    public let auth: CategoryConfiguration?
    public let hub: CategoryConfiguration?
    public let logging: CategoryConfiguration?
    public let storage: CategoryConfiguration?

    public init(analytics: CategoryConfiguration? = nil,
                api: CategoryConfiguration? = nil,
                auth: CategoryConfiguration? = nil,
                hub: CategoryConfiguration? = nil,
                logging: CategoryConfiguration? = nil,
                storage: CategoryConfiguration? = nil) {
        self.analytics = analytics
        self.api = api
        self.auth = auth
        self.hub = hub
        self.logging = logging
        self.storage = storage
    }
}
