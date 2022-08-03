import Foundation

protocol RandomStringBehavior {

    func generateUUID() -> String

    func generateRandom(byteSize: Int) -> String?
}
