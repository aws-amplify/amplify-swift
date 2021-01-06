//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthFetchDevicesOperation: AmplifyOperation<
    AuthFetchDevicesRequest,
    [AuthDevice],
    AuthError
>, AuthFetchDevicesOperation {

    let deviceService: AuthDeviceServiceBehavior

    init(_ request: AuthFetchDevicesRequest,
         deviceService: AuthDeviceServiceBehavior,
         resultListener: ResultListener?) {

        self.deviceService = deviceService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchDevicesAPI,
                   request: request,
                   resultListener: resultListener)
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

            if self.isCancelled {
                return
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
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
