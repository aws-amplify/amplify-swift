//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Detail view showing environment information
@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView: View {
    private let screenTitle  = "Environment Information"
    private let amplifyPluginSectionTitle  = "Amplify Plugins Information"
    private let devEnvSectionTitle  = "Developer Environment Information"

    /// Lists containing items belonging to two sections : Amplify Plugins and Developer Environment Informatoin
    private var amplifyPluginSectionItems = [PluginInfoItem]()
    private var devEnvSectionItems = [EnvironmentInfoItem]()

    init() {
        self.devEnvSectionItems = EnvironmentInfoHelper.fetchDeveloperInformationFromJson(
            filename: EnvironmentInfoHelper.environmentInfoSourceFileName)
        self.amplifyPluginSectionItems = PluginInfoHelper.getPluginInformation()
    }

    var body: some View {
        SwiftUI.List {
            Section(header: Text(amplifyPluginSectionTitle), footer: EmptyView()) {
                if amplifyPluginSectionItems.isEmpty {
                    NoItemView()
                } else {
                    ForEach(amplifyPluginSectionItems) { listItem in
                        InfoRow(infoItem: listItem)
                    }
                }
            }
            Section(header: Text(devEnvSectionTitle), footer: EmptyView()) {
                if devEnvSectionItems.isEmpty {
                    NoItemView()
                } else {
                    ForEach(devEnvSectionItems) { listItem in
                        InfoRow(infoItem: listItem)
                    }
                }
            }
        }
        .navigationBarTitle(screenTitle)
        .listStyle(GroupedListStyle())
    }
}

@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentInfoDetailView()
    }
}

@available(iOS 13.0, *)
struct NoItemView: View {
    var body: some View {
        HStack {
            Text("Information not available").padding(15)
            Spacer()
        }
    }
}
