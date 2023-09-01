//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSPinpointPushNotificationsPlugin: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.pushNotifications.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
