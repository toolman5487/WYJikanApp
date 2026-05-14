import SwiftUI

struct MyListCollectionStatusBadgeView: View {
    let isFavorite: Bool

    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.caption.weight(.bold))
            .foregroundStyle(ThemeColor.sakura)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
