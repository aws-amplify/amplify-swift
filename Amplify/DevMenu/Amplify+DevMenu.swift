//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Extension of `Amplify` for supporting Developer Menu feature
extension Amplify {

    @available(iOS 13.0.0, *)
    public static var devMenu: AmplifyDevMenu?

    @available(iOS 13.0.0, *)
    public static func enableDevMenu(contextProvider: DevMenuPresentationContextProvider) {
        #if DEBUG
            devMenu = AmplifyDevMenu(devMenuPresentationContextProvider: contextProvider)
        #else
            print("Developer Menu is available only in debug mode")
        #endif

    }

    /// Checks whether developer menu is enabled by developer
    @available(iOS 13.0.0, *)
    static func isDevMenuEnabled() -> Bool {
        return devMenu != nil
    }

    /// Returns a `PersistentLoggingPlugin` if developer menu feature is enabled in debug mode
    static func getLoggingCategoryPlugin() -> LoggingCategoryPlugin {
        if #available(iOS 13.0.0, *) {
            #if DEBUG
                if isDevMenuEnabled() {
                    return PersistentLoggingPlugin(plugin: AWSUnifiedLoggingPlugin())
                } else {
                    return AWSUnifiedLoggingPlugin()
                }
            #else
                return AWSUnifiedLoggingPlugin()
            #endif
        } else {
            return AWSUnifiedLoggingPlugin()
        }
    }

}
