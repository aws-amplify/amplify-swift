//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AwsCIo
import AwsCHttp
import AwsCommonRuntimeKit
import AWSPinpoint
import ClientRuntime
import Foundation

extension SdkError {
    private var clientError: ClientError? {
        guard case .client(let clientError, _) = self else {
            return nil
        }

        return clientError
    }
    
    private var crtError: CRTError? {
        if case .retryError(let crtError as CRTError) = clientError {
            return crtError
        }
        
        if case .crtError(let crtError) = clientError {
            return crtError
        }
        
        return nil
    }

    private var putEventsOutputError: PutEventsOutputError? {
        guard case .retryError(let sdkError as SdkError) = clientError,
              case .service(let putEventsError as PutEventsOutputError, _) = sdkError else {
            return nil
        }

        return putEventsError
    }

    private var awsError: AWSError? {
        guard case .crtError(let awsError) = crtError else {
            return nil
        }

        return awsError
    }

    var errorDescription: String {
        guard let putEventsOutputError = putEventsOutputError else {
            return awsError?.errorMessage ?? localizedDescription
        }

        switch putEventsOutputError {
        case .badRequestException(let exception as ServiceError),
             .forbiddenException(let exception as ServiceError),
             .internalServerErrorException(let exception as ServiceError),
             .methodNotAllowedException(let exception as ServiceError),
             .notFoundException(let exception as ServiceError),
             .payloadTooLargeException(let exception as ServiceError),
             .tooManyRequestsException(let exception as ServiceError),
             .unknown(let exception as ServiceError):
            return exception._message ?? localizedDescription
        }
    }
    
    private var rootError: Error? {
        if putEventsOutputError != nil {
            return putEventsOutputError
        }
        
        if crtError != nil {
            return crtError
        }
        
        guard let clientError = clientError else {
            return nil
        }
        
        switch clientError {
        case .networkError(let error),
             .deserializationFailed(let error),
             .retryError(let error):
            return error
        default:
            return nil
        }
    }

    var isConnectivityError: Bool {
        if case .networkError(_) = clientError {
            return true
        }

        guard let awsError = awsError else {
            return false
        }

        let connectivityErrorCodes: [UInt32] = [
            AWS_ERROR_HTTP_CONNECTION_CLOSED.rawValue,
            AWS_ERROR_HTTP_SERVER_CLOSED.rawValue,
            AWS_IO_DNS_INVALID_NAME.rawValue,
            AWS_IO_DNS_NO_ADDRESS_FOR_HOST.rawValue,
            AWS_IO_DNS_QUERY_FAILED.rawValue,
            AWS_IO_SOCKET_CONNECT_ABORTED.rawValue,
            AWS_IO_SOCKET_CONNECTION_REFUSED.rawValue,
            AWS_IO_SOCKET_CLOSED.rawValue,
            AWS_IO_SOCKET_NETWORK_DOWN.rawValue,
            AWS_IO_SOCKET_NO_ROUTE_TO_HOST.rawValue,
            AWS_IO_SOCKET_NOT_CONNECTED.rawValue,
            AWS_IO_SOCKET_TIMEOUT.rawValue,
            AWS_IO_TLS_NEGOTIATION_TIMEOUT.rawValue,
            UInt32(AWS_HTTP_STATUS_CODE_408_REQUEST_TIMEOUT.rawValue)
        ]

        return connectivityErrorCodes.contains(where: { $0 == awsError.errorCode })
    }

    var analyticsError: AnalyticsError {
        return .unknown(
            isConnectivityError ? AnalyticsPluginErrorConstant.deviceOffline.errorDescription : errorDescription,
            rootError ?? self
        )
    }
}
