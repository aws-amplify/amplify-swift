// swiftlint:disable all
import Amplify
import Foundation

public struct MyNestedModel8: Embeddable {
  var id: String
  var nestedName: String
  var notes: [String?]?
}