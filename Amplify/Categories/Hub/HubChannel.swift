//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// HubChannel represents the channels on which Amplify category messages will be dispatched
public enum HubChannel {

    /// Hub messages relating to the Amplify Core (e.g., configuration)
    case core

    /// Hub messages relating to Amplify Storage
    case storage
}
