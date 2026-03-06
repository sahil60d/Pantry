import SwiftUI

struct MealPlanResultView: View {
    let mealPlan: MealPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    recipeSection
                    if !mealPlan.missingIngredients.isEmpty {
                        groceryListSection
                    }
                }
                .padding()
            }
            .navigationTitle(mealPlan.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recipe", systemImage: "fork.knife")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(mealPlan.recipe)
                .lineSpacing(5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var groceryListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Grocery List", systemImage: "cart")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(mealPlan.missingIngredients, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
