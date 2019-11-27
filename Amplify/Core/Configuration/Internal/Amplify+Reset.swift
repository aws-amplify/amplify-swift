//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Amplify {

    /// Resets the state of the Amplify framework.
    ///
    /// Internally, this method:
    /// - Invokes `reset` on each configured category, which clears that categories registered plugins.
    /// - Releases each configured category, and replaces the instances referred to by the static accessor properties
    ///   (e.g., `Amplify.Hub`) with new instances. These instances must subsequently have providers added, and be
    ///   configured prior to use.
    static func reset() {
        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future

        let group = DispatchGroup()

        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                group.enter()
                DispatchQueue.global().async {
                    Analytics.reset { group.leave() }
                }
            case .api:
                group.enter()
                DispatchQueue.global().async {
                    API.reset { group.leave() }
                }
            case .dataStore:
                group.enter()
                DispatchQueue.global().async {
                    DataStore.reset { group.leave() }
                }
            case .hub:
                group.enter()
                DispatchQueue.global().async {
                    Hub.reset { group.leave() }
                }
            case .logging:
                group.enter()
                DispatchQueue.global().async {
                    Logging.reset { group.leave() }
                }
            case .storage:
                group.enter()
                DispatchQueue.global().async {
                    Storage.reset { group.leave() }
                }
            case .predictions:
                group.enter()
                DispatchQueue.global().async {
                    Predictions.reset { group.leave() }
                }
            }
        }

        group.wait()

        // Initialize Logging and Hub first, to ensure their default plugins are registered and available to other
        // categories during their initialization and configuration phases.
        Logging = LoggingCategory()
        Hub = HubCategory()

        // Switch over all category types to ensure we don't forget any
        for categoryType in CategoryType.allCases.filter({ $0 != .logging && $0 != .hub }) {
            switch categoryType {
            case .logging, .hub:
                // Initialized above
                break
            case .analytics:
                Analytics = AnalyticsCategory()
            case .api:
                API = APICategory()
            case .dataStore:
                DataStore = DataStoreCategory()
            case .predictions:
                Predictions = PredictionsCategory()
            case .storage:
                Storage = StorageCategory()
            }
        }

        isConfigured = false
    }

}
