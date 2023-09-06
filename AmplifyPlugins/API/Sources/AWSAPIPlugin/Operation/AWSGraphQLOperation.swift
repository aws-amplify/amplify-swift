//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

final public class AWSGraphQLOperation<R: Decodable>: GraphQLOperation<R> {

    let session: URLSessionBehavior
    let mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration
    let graphQLResponseDecoder: GraphQLResponseDecoder<R>

    init(request: GraphQLOperationRequest<R>,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         resultListener: AWSGraphQLOperation.ResultListener?) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig
        self.graphQLResponseDecoder = GraphQLResponseDecoder(request: request)

        super.init(categoryType: .api,
                   eventName: request.operationType.hubEventName,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        Amplify.API.log.debug("Starting \(request.operationType) \(id)")

        if isCancelled {
            finish()
            return
        }

        Task {
            let urlRequest = validateRequest(request).flatMap(buildURLRequest(from:))
            let finalRequest = await getEndpointInterceptors(from: request).flatMapAsync { requestInterceptors in
                var finalResult = urlRequest
                let amplifyInterceptors = requestInterceptors?.amplifyInterceptors ?? []
                let customerInterceptors = requestInterceptors?.interceptors ?? []
                let checksumInterceptors = requestInterceptors?.checksumInterceptors ?? []
                // apply amplify interceptors
                for interceptor in amplifyInterceptors {
                    finalResult = await finalResult.flatMapAsync { request in
                        await applyInterceptor(interceptor, request: request)
                    }
                }

                // there is no customer headers for GraphQLOperationRequest

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
                dispatch(result: .failure(error))
                finish()
            }
        }

    }

    private func validateRequest(_ request: GraphQLOperationRequest<R>) -> Result<GraphQLOperationRequest<R>, APIError> {
        do {
            try request.validate()
            return .success(request)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not validate request", "", nil))
        }
    }

    private func buildURLRequest(from request: GraphQLOperationRequest<R>) -> Result<URLRequest, APIError> {
        getEndpointConfig(from: request).flatMap { endpointConfig in
            getRequestPayload(from: request).map { requestPayload in
                GraphQLOperationRequestUtils.constructRequest(
                    with: endpointConfig.baseURL,
                    requestPayload: requestPayload
                )
            }
        }
    }

    private func getRequestPayload(from request: GraphQLOperationRequest<R>) -> Result<Data, APIError> {
        // Prepare request payload
        let queryDocument = GraphQLOperationRequestUtils.getQueryDocument(document: request.document,
                                                                          variables: request.variables)
        if Amplify.API.log.logLevel == .verbose,
           let serializedJSON = try? JSONSerialization.data(withJSONObject: queryDocument,
                                                            options: .prettyPrinted),
           let prettyPrintedQueryDocument = String(data: serializedJSON, encoding: .utf8) {
            Amplify.API.log.verbose("\(prettyPrintedQueryDocument)")
        }

        do {
            return .success(try JSONSerialization.data(withJSONObject: queryDocument))
        } catch {
            return .failure(APIError.operationError(
                "Failed to serialize query document",
                "fix the document or variables",
                error
            ))
        }
    }

    private func getEndpointConfig(from request: GraphQLOperationRequest<R>) -> Result<AWSAPICategoryPluginConfiguration.EndpointConfig, APIError> {
        do {
            return .success(try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL))
        } catch let error as APIError {
            return .failure(error)

        } catch {
            return .failure(APIError.unknown("Could not get endpoint configuration", "", nil))
        }
    }

    private func getEndpointInterceptors(from request: GraphQLOperationRequest<R>) -> Result<AWSAPIEndpointInterceptors?, APIError> {
        getEndpointConfig(from: request).flatMap { endpointConfig in
            do {
                if let pluginOptions = request.options.pluginOptions as? AWSPluginOptions,
                   let authType = pluginOptions.authType
                {
                    return .success(try pluginConfig.interceptorsForEndpoint(
                        withConfig: endpointConfig,
                        authType: authType
                    ))
                } else {
                    return .success(pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig))
                }
            } catch let error as APIError {
                return .failure(error)
            } catch {
                return .failure(APIError.unknown("Could not get endpoint interceptors", "", nil))
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
