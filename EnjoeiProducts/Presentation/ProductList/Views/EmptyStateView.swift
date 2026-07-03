import SwiftUI

struct EmptyStateView: View {
    let onClearSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ué, não encontramos nadinha")
                .font(AppFont.font(size: 22, weight: .bold, textStyle: .title2))

            Text("que tal recomeçar do começo?")
                .font(AppFont.font(size: 15, weight: .regular, textStyle: .subheadline))
                .foregroundStyle(ReadableGray.color)

            Button(action: onClearSearch) {
                Text("limpar busca")
                    .font(AppFont.font(size: 15, weight: .semibold, textStyle: .subheadline))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(BrandColor.color))
            }
            .accessibilityIdentifier("emptyStateClearButton")

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
