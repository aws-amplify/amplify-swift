//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View containing a list of developer menu items
@available(iOS 13.0.0, *)
struct DevMenuList: View {

    /// Integer tags to identify row items in Dev Menu
    public static let tagEnvironmentInformation = 0
    public static let tagDeviceInformation = 1
    public static let tagViewLogs = 2
    public static let tagFileIssue = 3

    /// Title corresponding to row items in Dev Menu
    public static let titleEnvironmentInformation = "View Environment Information"
    public static let titleDeviceInformation = "View Device Infomation"
    public static let titleViewLogs = "View Logs"
    public static let titleFileIssue = "File Issue"

    private let amplifyDevMenuListItems: [DevMenuItem] =
    [
        DevMenuItem(title: titleEnvironmentInformation, tag: tagEnvironmentInformation),
        DevMenuItem(title: titleDeviceInformation, tag: tagDeviceInformation),
        DevMenuItem(title: titleViewLogs, tag: tagViewLogs),
        DevMenuItem(title: titleFileIssue, tag: tagFileIssue)
    ]

    var body: some View {
        NavigationView {
            SwiftUI.List(amplifyDevMenuListItems) { listItem in
                NavigationLink(destination: DetailViewFactory.getDetailView(devMenuItemTag: listItem.tag)) {
                    DevMenuRow(rowItem: listItem)
                }
            }
            .navigationBarTitle(
                Text("Amplify Developer Menu"),
                displayMode: .inline)
        }

    }
}

@available(iOS 13.0.0, *)
struct AmplifyDevMenuList_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuList()
    }
}
