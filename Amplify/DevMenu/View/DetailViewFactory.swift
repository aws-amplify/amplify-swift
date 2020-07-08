//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A factory to create detail views based on `DevMenutItem`
@available(iOS 13.0, *)
public class DetailViewFactory {

    public static func getDetailView(devMenuItemTag: Int) -> AnyView {
        switch devMenuItemTag {
        case DevMenuList.tagDeviceInformation:
            return AnyView(DeviceInfoDetailView())
        default:
            return AnyView(EmptyView())
        }
    }

}
