import SwiftUI

struct ContentView: View {
    @Environment(PantryService.self) private var service
    @State private var showingAddIngredient = false
    @State private var generatedMealPlan: MealPlan?
    @State private var isGenerating = false
    @State private var generationError: String?

    private var ingredientsByCategory: [(category: String, ingredients: [Ingredient])] {
        let grouped = Dictionary(grouping: service.ingredients) {
            $0.category ?? "Uncategorized"
        }
        return grouped
            .map { (category: $0.key, ingredients: $0.value) }
            .sorted { $0.category < $1.category }
    }

    private var availableCount: Int {
        service.ingredients.filter(\.isAvailable).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading && service.ingredients.isEmpty {
                    ProgressView("Loading pantry...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if service.ingredients.isEmpty {
                    emptyState
                } else {
                    ingredientList
                }
            }
            .navigationTitle("Pantry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddIngredient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
            }
        }
        .task {
            await service.fetchIngredients()
        }
        .sheet(isPresented: $showingAddIngredient) {
            AddIngredientView()
        }
        .sheet(item: $generatedMealPlan) { mealPlan in
            MealPlanResultView(mealPlan: mealPlan)
        }
        .alert("Generation Failed", isPresented: .constant(generationError != nil)) {
            Button("OK") { generationError = nil }
        } message: {
            Text(generationError ?? "")
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Your pantry is empty")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to add your first ingredient")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ingredientList: some View {
        List {
            ForEach(ingredientsByCategory, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.ingredients) { ingredient in
                        IngredientRow(ingredient: ingredient)
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generateMealPlan() }
        } label: {
            Group {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Generate Meal Plan", systemImage: "wand.and.stars")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(availableCount == 0 ? Color.secondary : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isGenerating || availableCount == 0)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func generateMealPlan() async {
        isGenerating = true
        generationError = nil
        do {
            generatedMealPlan = try await service.generateMealPlan()
        } catch {
            generationError = error.localizedDescription
        }
        isGenerating = false
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    @Environment(PantryService.self) private var service
    let ingredient: Ingredient

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .fontWeight(.medium)
                if let quantity = ingredient.quantity, !quantity.isEmpty {
                    Text(quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Task {
                    try? await service.toggleAvailability(for: ingredient)
                }
            } label: {
                Image(systemName: ingredient.isAvailable ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(ingredient.isAvailable ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .opacity(ingredient.isAvailable ? 1.0 : 0.5)
    }
}
