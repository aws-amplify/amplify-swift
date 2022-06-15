//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class EndpointClient: InternalPinpointClient {
  unowned var context: PinpointContext

  init(context: PinpointContext) {
    self.context = context
  }

  func currentEndpointProfile() -> PinpointEndpointProfile {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func updateEndpointProfile() async throws {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func update(_ endpointProfile: PinpointEndpointProfile) async throws {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func addAttributes(_ attributes: [Any], forKey key: String) {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func removeAttributes(forKey key: String) {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func addMetric(_ metric: Double, forKey key: String) {
    // TODO: Implement
    fatalError("Not yet implemented")
  }

  func removeMetric(forKey key: String) {
    // TODO: Implement
    fatalError("Not yet implemented")
  }
}
