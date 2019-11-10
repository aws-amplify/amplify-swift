//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncSubscriptionConnection {

    func handleDataEvent(response: AppSyncResponse) {
        guard response.id == subscriptionItem.identifier else {
            return
        }
        switch response.responseType {
        case .data:
            let jsonEncode = JSONEncoder()
            do {
                let resultData = response.payload
                let jsonData = try jsonEncode.encode(resultData)
                subscriptionItem.subscriptionEventHandler(.data(jsonData), subscriptionItem)
            } catch {
                print(error)
                let jsonParserError = ConnectionProviderError.jsonParse(response.id, error)
                subscriptionItem.subscriptionEventHandler(.failed(jsonParserError), subscriptionItem)
            }
        case .subscriptionAck:
            subscriptionState = .subscribed
            subscriptionItem.subscriptionEventHandler(.connection(.connected), subscriptionItem)
        case .unsubscriptionAck:
            subscriptionState = .notSubscribed
            subscriptionItem.subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
        }
    }
}
