// swiftlint:disable all
import Amplify
import Foundation

extension Location1 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case lat
    case long
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let location1 = Location1.keys
    
    model.listPluralName = "Location1s"
    model.syncPluralName = "Location1s"
    
    model.fields(
      .field(location1.lat, is: .optional, ofType: .double),
      .field(location1.long, is: .optional, ofType: .double)
    )
    }
}