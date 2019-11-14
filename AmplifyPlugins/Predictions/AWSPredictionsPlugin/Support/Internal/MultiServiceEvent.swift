//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

enum MultiServiceEvent<ServiceResult> {

    /// Completed mutli service operation with result from two service
    /// The first result will be from the offline service and the second from the online service
    case completed(ServiceResult?, ServiceResult?)

    /// All multiple service failed
    case failed(PredictionsError)
}
