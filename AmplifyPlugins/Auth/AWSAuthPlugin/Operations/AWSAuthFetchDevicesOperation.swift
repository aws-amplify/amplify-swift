//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthFetchDevicesOperation: AmplifyOperation<AuthFetchDevicesRequest,
    Void,
    [AuthDevice],
    AmplifyAuthError>,
AuthFetchDevicesOperation {

    let deviceService: AuthDeviceServiceBehavior

    init(_ request: AuthFetchDevicesRequest,
         deviceService: AuthDeviceServiceBehavior,
         listener: EventListener?) {

        self.deviceService = deviceService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchDevices,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        deviceService.fetchDevices(request: request) { [weak self] result in
            guard let self = self else { return }

            defer {
                self.finish()
            }
            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let deviceList):
                self.dispatch(deviceList)
            }
        }
    }

    private func dispatch(_ result: [AuthDevice]) {
        let asyncEvent = AsyncEvent<Void, [AuthDevice], AmplifyAuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, [AuthDevice], AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
