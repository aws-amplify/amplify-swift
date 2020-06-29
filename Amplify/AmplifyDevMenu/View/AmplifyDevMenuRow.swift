//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

@available(iOS 13.0.0, *)
struct AmplifyDevMenuRow: View {
    var rowItem: AmplifyDevMenuItem

    var body: some View {
        HStack {
            Spacer()
            Text(rowItem.title)
            Spacer()
        }
    }
}

@available(iOS 13.0.0, *)
struct AmplifyDevMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        AmplifyDevMenuRow(rowItem: AmplifyDevMenuItem(title: "View Environment Information")!)
    }
}
