// swiftlint:disable all
import Amplify
import Foundation

extension Dish {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case dishName
    case menu
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let dish = Dish.keys
    
    model.pluralName = "Dishes"
    
    model.fields(
      .id(),
      .field(dish.dishName, is: .optional, ofType: .string),
      .belongsTo(dish.menu, is: .optional, ofType: Menu.self, targetName: "dishMenuId")
    )
    }
}