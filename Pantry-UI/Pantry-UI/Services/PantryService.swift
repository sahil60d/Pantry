import Foundation
import Observation
import Supabase

@Observable
final class PantryService {
    private(set) var ingredients: [Ingredient] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let supabase: SupabaseClient

    init() {
        guard
            let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String
        else {
            fatalError("Missing Supabase credentials in Info.plist. Check Config.xcconfig setup.")
        }
        supabase = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - Ingredients

    func fetchIngredients() async {
        isLoading = true
        errorMessage = nil
        do {
            ingredients = try await supabase
                .from("ingredients")
                .select()
                .order("category", ascending: true)
                .order("name", ascending: true)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addIngredient(name: String, category: String, quantity: String) async throws {
        struct NewIngredient: Encodable {
            let name: String
            let category: String
            let quantity: String
            let isAvailable = true

            enum CodingKeys: String, CodingKey {
                case name, category, quantity
                case isAvailable = "is_available"
            }
        }

        try await supabase
            .from("ingredients")
            .insert(NewIngredient(name: name, category: category, quantity: quantity))
            .execute()

        await fetchIngredients()
    }

    func toggleAvailability(for ingredient: Ingredient) async throws {
        try await supabase
            .from("ingredients")
            .update(["is_available": !ingredient.isAvailable])
            .eq("id", value: ingredient.id)
            .execute()

        await fetchIngredients()
    }

    // MARK: - Meal Plans

    func generateMealPlan() async throws -> MealPlan {
        let availableNames = ingredients
            .filter(\.isAvailable)
            .map(\.name)

        guard !availableNames.isEmpty else {
            throw PantryError.noIngredientsAvailable
        }

        struct GenerateRequest: Encodable {
            let ingredients: [String]
        }

        struct GeneratedMeal: Decodable {
            let title: String
            let recipe: String
            let missingIngredients: [String]

            enum CodingKeys: String, CodingKey {
                case title, recipe
                case missingIngredients = "missing_ingredients"
            }
        }

        let response = try await supabase.functions.invoke(
            "generate-meal",
            options: .init(body: GenerateRequest(ingredients: availableNames))
        )
        let generated = try JSONDecoder().decode(GeneratedMeal.self, from: response.data)

        struct NewMealPlan: Encodable {
            let title: String
            let recipe: String
            let missingIngredients: [String]

            enum CodingKeys: String, CodingKey {
                case title, recipe
                case missingIngredients = "missing_ingredients"
            }
        }

        let saved: [MealPlan] = try await supabase
            .from("meal_plans")
            .insert(NewMealPlan(
                title: generated.title,
                recipe: generated.recipe,
                missingIngredients: generated.missingIngredients
            ))
            .select()
            .execute()
            .value

        guard let mealPlan = saved.first else {
            throw PantryError.saveFailed
        }
        return mealPlan
    }
}

// MARK: - Errors

enum PantryError: LocalizedError {
    case noIngredientsAvailable
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noIngredientsAvailable:
            return "No available ingredients. Mark some ingredients as available first."
        case .saveFailed:
            return "The meal plan was generated but could not be saved."
        }
    }
}
