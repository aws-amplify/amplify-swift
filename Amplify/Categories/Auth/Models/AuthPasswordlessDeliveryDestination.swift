//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Delivery destination for the Auth Passwordless flows
///
public enum AuthPasswordlessDeliveryDestination: String {
   case sms = "SMS"
   case email = "EMAIL"
}
