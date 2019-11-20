//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSRESTOperation: APIOperation {
    func getOperationId() -> UUID {
        return id
    }

    func cancelOperation() {
        cancel()
    }

    func updateProgress(_ data: Data, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        let apiOperationResponse = APIOperationResponse(error: nil, response: response)
        do {
            try apiOperationResponse.validate()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("", "", error)))
            finish()
            return
        }

        self.data.append(data)
    }

    func complete(with error: Error?, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        let apiOperationResponse = APIOperationResponse(error: error, response: response)
        do {
            try apiOperationResponse.validate()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("", "", error)))
            finish()
            return
        }

        dispatch(event: .completed(data))
        finish()
    }
}
