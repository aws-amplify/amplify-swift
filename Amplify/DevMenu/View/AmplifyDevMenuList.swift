//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View containing a list of developer menu items
@available(iOS 13.0.0, *)
struct AmplifyDevMenuList: View {
    var amplifyDevMenuListItems: [AmplifyDevMenuItem] =
    [
        AmplifyDevMenuItem(title: "View Environment Information"),
        AmplifyDevMenuItem(title: "View Device Infomation"),
        AmplifyDevMenuItem(title: "View Logs"),
        AmplifyDevMenuItem(title: "File Issue")
    ]

    var body: some View {
        NavigationView {
            SwiftUI.List(amplifyDevMenuListItems) { listItem in
                AmplifyDevMenuRow(rowItem: listItem)
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
        AmplifyDevMenuList()
    }
}
