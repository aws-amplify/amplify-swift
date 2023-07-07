//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSPinpointPushNotificationsPlugin: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.pushNotifications.displayName)
    }
    public var log: Logger {
        Self.log
    }
}
