import Foundation

struct Ingredient: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var name: String
    var category: String?
    var quantity: String?
    var isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case category
        case quantity
        case isAvailable = "is_available"
    }
}
