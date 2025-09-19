//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum AppSyncSubscriptionEvent {
    case subscribing
    case subscribed
    case data(JSONValue)
    case unsubscribed
    case error([Error])
}
