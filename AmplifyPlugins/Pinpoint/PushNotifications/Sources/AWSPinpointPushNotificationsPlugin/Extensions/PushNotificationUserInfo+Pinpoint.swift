//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension PushNotification.UserInfo {
    private var root: [String: Any]? {
        guard let data = self[Constants.Keys.data] as? [String: Any],
              let root = data[Constants.Keys.pinpoint] as? [String: Any] else {
            return nil
        }

        return root
    }

    var payload: PushNotification.Payload? {
        guard let root = root else {
            return nil
        }

        if let campaignAttributes = root[Constants.Keys.campaing] as? [String: String] {
            return .init(source: .campaign, attributes: campaignAttributes)
        } else if let journeyAttributes = root[Constants.Keys.journey] as? [String: String] {
            return .init(source: .journey, attributes: journeyAttributes)
        }

        return nil
    }

    var deeplinkUrl: URL? {
        if let urlString = root?[Constants.Keys.deeplink] as? String,
           let deeplinkUrl = URL(string: urlString) {
            return deeplinkUrl
        }
        return nil
    }
}

extension PushNotification.UserInfo {
    private struct Constants {
        struct Keys {
            static let data = "data"
            static let pinpoint = "pinpoint"
            static let campaing = "campaign"
            static let journey = "journey"
            static let deeplink = "deeplink"
        }
    }
}
