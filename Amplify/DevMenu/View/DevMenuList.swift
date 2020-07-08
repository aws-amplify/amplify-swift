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

    private let screenTitle = "Amplify Developer Menu"

    /// Item labels for each row in the Developer Menu
    public enum ItemLabel {
        case environmentInformation
        case deviceInformation
        case logViewer
        case reportIssue

        var stringValue: String {
            switch self {
            case .environmentInformation:
                return "Environment Information"
            case  .deviceInformation:
                return "Device Information"
            case .logViewer:
                return "Log Viewer"
            case .reportIssue:
                return "Report Issue"
            }
        }

        // systemName parameter for SFSymbols used in `UIImage(systemName:)` initializer
        var iconName: String {
            switch self {
            case .environmentInformation:
                return "globe"
            case  .deviceInformation:
                return "desktopcomputer"
            case .logViewer:
                return "eyeglasses"
            case .reportIssue:
                return "exclamationmark.circle"
            }
        }
    }

    private let amplifyDevMenuListItems: [DevMenuItem] =
    [
        DevMenuItem(label: .environmentInformation),
        DevMenuItem(label: .deviceInformation),
        DevMenuItem(label: .logViewer),
        DevMenuItem(label: .reportIssue)
    ]

    var body: some View {
        NavigationView {
            SwiftUI.List(amplifyDevMenuListItems) { listItem in
                NavigationLink(destination: DetailViewFactory.getDetailView(devMenuItemLabel: listItem.label)) {
                    DevMenuRow(rowItem: listItem)
                }
            }
            .navigationBarTitle(
                Text(screenTitle),
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
