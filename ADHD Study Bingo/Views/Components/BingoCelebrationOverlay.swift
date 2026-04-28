import SwiftUI

struct BingoCelebrationOverlay: View {
    @Binding var showPopup: Bool
    let confettiBurstID: Int
    let lineCount: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            #if os(iOS)
            ConfettiEmitterView(burstID: confettiBurstID)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            #endif

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.green.opacity(0.65), lineWidth: 2)
                )
                .frame(width: 300, height: 120)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 7)
                .overlay {
                    VStack(spacing: 6) {
                        Text("🎉 BINGO!")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.green.opacity(0.72))
                        Text("Awesome! \(lineCount) lines completed")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .scaleEffect(showPopup ? 1 : 0.82)
                .opacity(showPopup ? 1 : 0)
                .animation(.spring(response: 0.32, dampingFraction: 0.72), value: showPopup)
        }
        .transition(.opacity)
    }
}
