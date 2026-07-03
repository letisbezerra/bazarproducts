import SwiftUI

struct EmptyStateView: View {
    let onClearSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ué, não encontramos nadinha")
                .font(AppFont.font(size: 22, weight: .bold))

            Text("que tal recomeçar do começo?")
                .font(AppFont.font(size: 15, weight: .regular))
                .foregroundStyle(ReadableGray.color)

            Button(action: onClearSearch) {
                Text("limpar busca")
                    .font(AppFont.font(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(BrandColor.color))
            }

            Spacer()

            Image("EmptyStateMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        }
        .padding(24)
    }
}

#Preview {
    EmptyStateView(onClearSearch: {})
}
