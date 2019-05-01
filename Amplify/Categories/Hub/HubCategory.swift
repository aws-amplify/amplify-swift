//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class HubCategory: BaseCategory<CategoryMarker.Hub, AnyHubCategoryPlugin> { }

extension HubCategory: HubCategoryClientBehavior {
    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        defaultPlugin.dispatch(to: channel, payload: payload)
    }
}
