import SwiftUI

struct EmptyStateView: View {
    let onClearSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ué, não encontramos nadinha")
                .font(.title2.bold())

            Text("que tal recomeçar do começo?")
                .font(.body)
                .foregroundStyle(.secondary)

            Button(action: onClearSearch) {
                Text("limpar busca")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color("BrandPurple")))
            }

            Spacer()

            HStack {
                Spacer()
                // Placeholder for the Figma mascot illustration -- not yet exported as an asset,
                // see the open blocker in docs/PLAN.md.
                Image(systemName: "figure.wave")
                    .font(.system(size: 100))
                    .foregroundStyle(Color("BrandPurple").opacity(0.5))
            }
        }
        .padding(24)
    }
}

#Preview {
    EmptyStateView(onClearSearch: {})
}
