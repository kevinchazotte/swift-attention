import SwiftUI

struct BackgroundView: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 20
            let cols = Int(size.width / tileSize) + 1
            let rows = Int(size.height / tileSize) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * tileSize
                    let y = CGFloat(row) * tileSize
                    let hue = Double.random(in: 0.15...0.25)
                    let saturation = Double.random(in: 0.6...0.9)
                    let brightness = Double.random(in: 0.75...0.95)
                    let color = Color(hue: hue, saturation: saturation, brightness: brightness)
                    context.fill(Path(CGRect(x: x, y: y, width: tileSize, height: tileSize)), with: .color(color))
                }
            }
        }.ignoresSafeArea()
    }
}
