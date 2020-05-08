//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AuthUpdateAttributeStep {

    case confirmAttributeWithCode(AuthCodeDeliveryDetails, AdditionalInfo?)

    case done
}
