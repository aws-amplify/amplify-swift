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

    @available(iOS 13.0.0, *)
    public static func enableDevMenu(devMenuDelegate: DevMenuDelegate) {
        #if DEBUG
            devMenu = AmplifyDevMenu(delegate: devMenuDelegate)
        #else
            print("Dev Menu is available only in debug mode")
        #endif

    }

    @available(iOS 13.0.0, *)
    static func isDevMenuEnabled() -> Bool {
        return devMenu != nil
    }

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
