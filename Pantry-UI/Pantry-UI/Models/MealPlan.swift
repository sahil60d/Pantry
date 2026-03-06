import Foundation

struct MealPlan: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let title: String
    let recipe: String
    let missingIngredients: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case recipe
        case missingIngredients = "missing_ingredients"
    }
}
