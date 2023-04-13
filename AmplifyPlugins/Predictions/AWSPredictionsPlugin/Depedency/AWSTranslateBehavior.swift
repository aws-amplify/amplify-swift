//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate

struct PredictionServiceClientFetching<Service, Client> {
    let getClient: (Service) -> Client
}

extension PredictionServiceClientFetching where
    Service: PredictionsServiceBehavior,
    Client == TranslateClient {


}

struct ServiceBehavior<A, B> {

}

protocol PredictionsServiceBehavior {
    associatedtype Client
    func getClient() -> Client
}

protocol AWSTranslateBehavior {
    func translateText(
        request: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse

    func getTranslate() async throws -> TranslateClient
}
