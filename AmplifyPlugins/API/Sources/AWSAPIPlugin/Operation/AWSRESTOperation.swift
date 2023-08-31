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
        let amplifyInterceptors: [URLRequestInterceptor]
        let customerInterceptors: [URLRequestInterceptor]
        let checksumInterceptors: [URLRequestInterceptor]
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .rest)
            let interceptorConfig = pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig)
            amplifyInterceptors = interceptorConfig?.amplifyInterceptors ?? []
            customerInterceptors = interceptorConfig?.interceptors ?? []
            checksumInterceptors = interceptorConfig?.checksumInterceptors ?? []
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
            url = try RESTOperationRequestUtils.constructURL(
                for: endpointConfig.baseURL,
                withPath: request.path,
                withParams: request.queryParameters
            )
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
        let urlRequest = RESTOperationRequestUtils.constructURLRequest(
            with: url,
            operationType: request.operationType,
            requestPayload: request.body
        )

        Task {
            var finalResult: Result<URLRequest, APIError> = .success(urlRequest)
            // apply amplify interceptors
            for interceptor in amplifyInterceptors {
                finalResult = await finalResult.flatMapAsync { request in
                    await applyInterceptor(interceptor, request: request)
                }
            }

            // apply customer headers
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

            // apply checksum interceptor
            for interceptor in checksumInterceptors {
                finalResult = await finalResult.flatMapAsync { request in
                    await applyInterceptor(interceptor, request: request)
                }
            }

            switch finalResult {
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
                dispatch(result: .failure(error))
                cancel()
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
