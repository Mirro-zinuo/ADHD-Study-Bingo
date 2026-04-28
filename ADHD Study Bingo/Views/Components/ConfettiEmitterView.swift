import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
final class ConfettiEmitterContainerView: UIView {
    let emitterLayer = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterPosition = .zero
        emitterLayer.emitterSize = .zero
        emitterLayer.birthRate = 0
        layer.addSublayer(emitterLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = bounds.size
    }

    func fireBurst() {
        emitterLayer.beginTime = CACurrentMediaTime()
        emitterLayer.birthRate = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
    }
}

struct ConfettiEmitterView: UIViewRepresentable {
    var burstID: Int

    final class Coordinator {
        var lastBurstID: Int = -1
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ConfettiEmitterContainerView {
        let view = ConfettiEmitterContainerView()
        view.emitterLayer.emitterCells = makeCells()
        return view
    }

    func updateUIView(_ uiView: ConfettiEmitterContainerView, context: Context) {
        if context.coordinator.lastBurstID != burstID {
            context.coordinator.lastBurstID = burstID
            if burstID > 0 {
                uiView.fireBurst()
            }
        }
    }

    private func makeCells() -> [CAEmitterCell] {
        let colors: [UIColor] = [
            UIColor.systemGreen.withAlphaComponent(0.75),
            UIColor.systemYellow.withAlphaComponent(0.85),
            UIColor.systemGray.withAlphaComponent(0.70)
        ]

        return colors.map { color in
            let cell = CAEmitterCell()
            cell.contents = rectangleImage(color: color).cgImage
            cell.birthRate = 20
            cell.lifetime = 2.1
            cell.lifetimeRange = 0.5
            cell.velocity = 180
            cell.velocityRange = 80
            cell.yAcceleration = 220
            cell.emissionLongitude = .pi / 2
            cell.emissionRange = .pi / 5
            cell.spin = 2.5
            cell.spinRange = 2.0
            cell.scale = 1
            return cell
        }
    }

    private func rectangleImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 8, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif
