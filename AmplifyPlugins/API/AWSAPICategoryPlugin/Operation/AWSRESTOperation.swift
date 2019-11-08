//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSRESTOperation: AmplifyOperation<RESTRequest,
    Void,
    Data,
    APIError
    >,
RESTOperation {

    // Data received by the operation
    var data = Data()

    let session: URLSessionBehavior
    var mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration

    // TODO: fix possible inconsistent request.operationType and eventName passed in, by removing eventName
    // and retrieveing it from request.operationType.mapToEventName() for example.
    init(request: RESTRequest,
         eventName: String,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         listener: AWSRESTOperation.EventListener?) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig

        super.init(categoryType: .api,
                   eventName: eventName,
                   request: request,
                   listener: listener)

    }

    /// The work to execute for this operation
    override public func main() {
        if isCancelled {
            finish()
            return
        }

        // Validate the request
        if let error = request.validate() {
            dispatch(event: .failed(error))
            finish()
            return
        }

        // Retrieve endpoint configuration
        guard let endpointConfig = pluginConfig.endpoints[request.apiName] else {
            let error = APIError.invalidConfiguration(
                "Unable to get an endpoint configuration for \(request.apiName)",
                """
                Review your API plugin configuration and ensure \(request.apiName) has a valid configuration.
                """
            )
            dispatch(event: .failed(error))
            finish()
            return
        }

        // Construct URL with path
        let url: URL
        do {
            url = try RESTRequestUtils.constructURL(endpointConfig.baseURL, path: request.path)
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            let apiError = APIError.operationError("Failed to construct URL", "", error)
            dispatch(event: .failed(apiError))
            finish()
            return
        }

        // Construct Request
        let urlRequest = RESTRequestUtils.constructRequest(with: url,
                                                           operationType: request.operationType,
                                                           requestPayload: request.body)

        // Intercept request
        let finalRequest = endpointConfig.interceptors.reduce(urlRequest) { (request, interceptor) -> URLRequest in
            do {
                return try interceptor.intercept(request)
            } catch {
                dispatch(event: .failed(APIError.operationError("Failed to intercept request fully.",
                                                                "Something wrong with the interceptor",
                                                                error)))
                cancel()
                return request
            }
        }

        // Begin network task
        let task = session.dataTaskBehavior(with: finalRequest)
        mapper.addPair(operation: self, task: task)
        task.resume()
    }
}
