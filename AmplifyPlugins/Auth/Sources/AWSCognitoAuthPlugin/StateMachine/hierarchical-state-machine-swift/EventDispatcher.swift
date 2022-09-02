//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol EventDispatcher {
    func send(_ event: StateMachineEvent) async
}
