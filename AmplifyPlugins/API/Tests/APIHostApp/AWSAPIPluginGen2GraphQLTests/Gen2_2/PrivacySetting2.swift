// swiftlint:disable all
import Amplify
import Foundation

public enum PrivacySetting2: String, EnumPersistable {
  case `private` = "PRIVATE"
  case friendsOnly = "FRIENDS_ONLY"
  case `public` = "PUBLIC"
}