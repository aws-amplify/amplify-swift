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
        Task { await mainAsync() }
    }

    private func mainAsync() async {
        if isCancelled {
            finish()
            return
        }

        let urlRequest = validateRequest(request).flatMap(buildURLRequest(from:))
        let finalRequest = await getEndpointConfig(from: request).flatMapAsync { endpointConfig in
            let interceptorConfig = pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig)
            let preludeInterceptors = interceptorConfig?.preludeInterceptors ?? []
            let customerInterceptors = interceptorConfig?.interceptors ?? []
            let postludeInterceptors = interceptorConfig?.postludeInterceptors ?? []

            var finalResult = urlRequest
            // apply prelude interceptors
            for interceptor in preludeInterceptors {
                finalResult = await finalResult.flatMapAsync { request in
                    await applyInterceptor(interceptor, request: request)
                }
            }

            // apply customize headers
            finalResult = finalResult.map { urlRequest in
                var mutableRequest = urlRequest
                for (key, value) in request.headers ?? [:] {
                    mutableRequest.setValue(value, forHTTPHeaderField: key)
                }
                return mutableRequest
            }

            // apply customer interceptors
            for interceptor in customerInterceptors {
                finalResult = await finalResult.flatMapAsync { request in
                    await applyInterceptor(interceptor, request: request)
                }
            }

            // apply postlude interceptor
            for interceptor in postludeInterceptors {
                finalResult = await finalResult.flatMapAsync { request in
                    await applyInterceptor(interceptor, request: request)
                }
            }
            return finalResult
        }

        switch finalRequest {
        case .success(let finalRequest):
            if isCancelled {
                finish()
                return
            }

            // Begin network task
            Amplify.API.log.debug("Starting network task for \(request.operationType) \(id)")
            let task = session.dataTaskBehavior(with: finalRequest)
            mapper.addPair(operation: self, task: task)
            task.resume()
        case .failure(let error):
            Amplify.API.log.debug("Dispatching error \(error)")
            dispatch(result: .failure(error))
            finish()
        }
    }

    private func validateRequest(_ request: RESTOperationRequest) -> Result<RESTOperationRequest, APIError> {
        do {
            try request.validate()
            return .success(request)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not validate request", "", nil))
        }
    }

    private func getEndpointConfig(
        from request: RESTOperationRequest
    ) -> Result<AWSAPICategoryPluginConfiguration.EndpointConfig, APIError> {
        do {
            return .success(try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .rest))
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not get endpoint configuration", "", nil))
        }
    }

    private func buildURLRequest(from request: RESTOperationRequest) -> Result<URLRequest, APIError> {
        getEndpointConfig(from: request).flatMap { endpointConfig in
            do {
                let url = try RESTOperationRequestUtils.constructURL(
                    for: endpointConfig.baseURL,
                    withPath: request.path,
                    withParams: request.queryParameters
                )
                return .success(RESTOperationRequestUtils.constructURLRequest(
                    with: url,
                    operationType: request.operationType,
                    requestPayload: request.body
                ))
            } catch let error as APIError {
                return .failure(error)
            } catch {
                return .failure(APIError.operationError("Failed to construct URL", "", error))
            }
        }
    }

    private func applyInterceptor(_ interceptor: URLRequestInterceptor, request: URLRequest) async -> Result<URLRequest, APIError> {
        do {
            return .success(try await interceptor.intercept(request))
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(
                APIError.operationError(
                    "Failed to intercept request fully.",
                    "Something wrong with the interceptor",
                    error
                )
            )
        }
    }
}
