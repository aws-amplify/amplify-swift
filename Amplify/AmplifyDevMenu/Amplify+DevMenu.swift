//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Amplify {

    @available(iOS 13.0.0, *)
    public static var devMenu: AmplifyDevMenu?

    static var isDeveloperMenuEnabled = false

    @available(iOS 13.0.0, *)
    public static func enableDevMenu(devMenuDelegate: DevMenuDelegate) {
        devMenu = AmplifyDevMenu(delegate: devMenuDelegate)
        isDeveloperMenuEnabled = true
    }

    static func isDevMenuEnabled() -> Bool {
        return isDeveloperMenuEnabled
    }

    static func getLoggingCategoryPlugin() -> LoggingCategoryPlugin {
        #if DEBUG
        if isDevMenuEnabled() {
            return PersistentLoggingPlugin(plugin: AWSUnifiedLoggingPlugin())
        } else {
            return AWSUnifiedLoggingPlugin()
        }
        #else
            return AWSUnifiedLoggingPlugin()
        #endif
    }

}
