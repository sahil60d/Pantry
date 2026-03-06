import SwiftUI

struct AddIngredientView: View {
    @Environment(PantryService.self) private var service
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = ""
    @State private var quantity = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let suggestedCategories = [
        "Protein", "Vegetables", "Fruits", "Grains",
        "Dairy", "Fats & Oils", "Condiments", "Spices"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Chicken Breast)", text: $name)
                    TextField("Quantity (e.g. 2 lbs)", text: $quantity)
                }

                Section("Category") {
                    TextField("Category", text: $category)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedCategories, id: \.self) { suggestion in
                                Button(suggestion) {
                                    category = suggestion
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(category == suggestion ? .accentColor : .secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await submit() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
    }

    // MARK: - Actions

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await service.addIngredient(
                name: name.trimmingCharacters(in: .whitespaces),
                category: category.trimmingCharacters(in: .whitespaces),
                quantity: quantity.trimmingCharacters(in: .whitespaces)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
