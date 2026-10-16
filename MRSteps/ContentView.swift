import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameSceneStore()

    var body: some View {
        SpriteView(scene: store.scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .persistentSystemOverlays(.hidden)
    }
}

private final class GameSceneStore: ObservableObject {
    let scene: GameScene

    init() {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        self.scene = scene
    }
}
