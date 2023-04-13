//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSRESTOperation: AmplifyOperation<
    RESTOperationRequest,
    Data,
    APIError
>, RESTOperation {

    // Data received by the operation
    var data = Data()

    let session: URLSessionBehavior
    var mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration

    init(request: RESTOperationRequest,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         resultListener: AWSRESTOperation.ResultListener?) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig

        super.init(categoryType: .api,
                   eventName: request.operationType.hubEventName,
                   request: request,
                   resultListener: resultListener)

    }

    /// The work to execute for this operation
    override public func main() {
        if isCancelled {
            finish()
            return
        }

        // Validate the request
        do {
            try request.validate()
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not validate request", "", nil)))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        let requestInterceptors: [URLRequestInterceptor]
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .rest)
            requestInterceptors = try pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig)
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not get endpoint configuration", "", nil)))
            finish()
            return
        }

        // Construct URL with path
        let url: URL
        do {
            url = try RESTOperationRequestUtils.constructURL(for: endpointConfig.baseURL,
                                                             with: request.path,
                                                             with: request.queryParameters)
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            let apiError = APIError.operationError("Failed to construct URL", "", error)
            dispatch(result: .failure(apiError))
            finish()
            return
        }

        // Construct URL Request with url and request body
        let urlRequest = RESTOperationRequestUtils.constructURLRequest(with: url,
                                                                       operationType: request.operationType,
                                                                       headers: request.headers,
                                                                       requestPayload: request.body)

        // Intercept request
        let finalRequest = requestInterceptors.reduce(urlRequest) { (request, interceptor) -> URLRequest in
            do {
                return try interceptor.intercept(request)
            } catch let error as APIError {
                dispatch(result: .failure(error))
                cancel()
                return request
            } catch {
                dispatch(result: .failure(APIError.operationError("Failed to intercept request fully.",
                                                                  "Something wrong with the interceptor",
                                                                  error)))
                cancel()
                return request
            }
        }

        if isCancelled {
            finish()
            return
        }

        // Begin network task
        let task = session.dataTaskBehavior(with: finalRequest)
        mapper.addPair(operation: self, task: task)
        task.resume()
    }
}

