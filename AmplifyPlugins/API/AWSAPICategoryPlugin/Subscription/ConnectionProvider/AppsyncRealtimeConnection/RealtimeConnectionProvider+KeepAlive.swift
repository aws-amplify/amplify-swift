//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider {

    /// Check if the we got a keep alive message within the given timeout window.
    /// If we did not get the keepalive, disconnect the connection and return an error.
    func disconnectIfStale() {

        // Validate the connection only when it is connected or inprogress state.
        guard status != .notConnected else {
            return
        }
        AppSyncLogger.verbose("Validating connection")
        let staleThreshold = lastKeepAliveTime + staleConnectionTimeout
        let currentTime = DispatchTime.now()
        if staleThreshold < currentTime {

            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }
                self.status = .notConnected
                self.websocket.disconnect()
                AppSyncLogger.error("Realtime connection is stale, disconnected.")
                self.updateCallback(event: .error(ConnectionProviderError.connection))
            }

        } else {
            DispatchQueue.global().asyncAfter(deadline: currentTime + staleConnectionTimeout) { [weak self] in
                self?.disconnectIfStale()
            }
        }

    }
}
