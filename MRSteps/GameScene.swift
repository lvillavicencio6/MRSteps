import SpriteKit

final class GameScene: SKScene {

    private enum State {
        case menu, playing, gameOver
    }

    private enum Side {
        case left, right

        var opposite: Side { self == .left ? .right : .left }
        var sign: CGFloat { self == .left ? -1 : 1 }
    }

    private struct Step {
        let node: SKSpriteNode
        let x: CGFloat
        let worldY: CGFloat
        let cracked: Bool
    }

    private var state: State = .menu
    private var world = SKNode()
    private var hud = SKNode()
    private var character: SKSpriteNode!
    private var arrow: SKSpriteNode!
    private var beatFill: SKSpriteNode!
    private var beatTrack: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var overlay = SKNode()

    private var steps: [Step] = []
    private var currentIndex = 0
    private var nextSide: Side = .right
    private var score = 0
    private var best = UserDefaults.standard.integer(forKey: "bestScore")
    private var isBusy = false
    private var beatRemaining: TimeInterval = 1.35
    private var beatMax: TimeInterval = 1.35
    private var lastUpdate: TimeInterval = 0

    private var homeY: CGFloat { size.height * 0.36 }
    private var stepHeight: CGFloat { CGFloat(Layout.stepPixelH) * Layout.artScale }
    private var heroHeight: CGFloat { 18 * Layout.heroScale }
    private var didSetup = false

    override func didMove(to view: SKView) {
        backgroundColor = Theme.skyTop
        anchorPoint = .zero
        isUserInteractionEnabled = true
        guard !didSetup else {
            buildBackground()
            return
        }
        didSetup = true
        buildBackground()
        addChild(world)
        addChild(hud)
        addChild(overlay)
        setupHUD()
        showMenu(animated: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard didSetup, oldSize != size, size.width > 0 else { return }
        buildBackground()
        layoutHUD()
        if state == .menu {
            showMenu(animated: false)
        }
    }

    // MARK: - Setup

    private func buildBackground() {
        childNode(withName: "sky")?.removeFromParent()

        let sky = SKNode()
        sky.name = "sky"
        sky.zPosition = -20
        insertChild(sky, at: 0)

        let bottom = SKSpriteNode(color: Theme.skyBottom, size: size)
        bottom.anchorPoint = .zero
        sky.addChild(bottom)

        let top = SKSpriteNode(color: Theme.skyTop, size: CGSize(width: size.width, height: size.height * 0.55))
        top.anchorPoint = .zero
        top.position = CGPoint(x: 0, y: size.height * 0.45)
        sky.addChild(top)

        let moon = SKSpriteNode(color: Theme.moon, size: CGSize(width: 54, height: 54))
        moon.position = CGPoint(x: size.width * 0.82, y: size.height * 0.82)
        sky.addChild(moon)

        let moonCut = SKSpriteNode(color: Theme.skyTop, size: CGSize(width: 42, height: 42))
        moonCut.position = CGPoint(x: 14, y: 10)
        moon.addChild(moonCut)

        for i in 0..<18 {
            let star = SKSpriteNode(color: Theme.star, size: CGSize(width: i % 4 == 0 ? 4 : 2, height: i % 4 == 0 ? 4 : 2))
            star.position = CGPoint(
                x: CGFloat((i * 47 + 13) % max(Int(size.width), 1)),
                y: size.height * (0.55 + CGFloat((i * 17) % 40) / 100)
            )
            star.alpha = 0.35 + CGFloat(i % 5) * 0.12
            sky.addChild(star)
            star.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.15, duration: 0.8 + Double(i % 4) * 0.2),
                .fadeAlpha(to: 0.9, duration: 0.8 + Double(i % 3) * 0.2)
            ])))
        }

        for i in 0..<4 {
            let cloud = SKSpriteNode(texture: PixelArt.cloud())
            cloud.setScale(4)
            cloud.position = CGPoint(x: CGFloat(i) * 180 - 40, y: size.height * (0.58 + CGFloat(i % 2) * 0.12))
            cloud.alpha = 0.55
            sky.addChild(cloud)
            let dx = size.width + 220
            cloud.run(.repeatForever(.sequence([
                .moveBy(x: dx, y: 0, duration: 28 + Double(i) * 4),
                .moveBy(x: -dx, y: 0, duration: 0)
            ])))
        }
    }

    private func setupHUD() {
        hud.zPosition = 50

        beatTrack = SKSpriteNode(color: Theme.ink, size: CGSize(width: 220, height: 16))
        beatTrack.position = CGPoint(x: 0, y: 0)
        beatTrack.zPosition = 51
        beatTrack.isHidden = true
        hud.addChild(beatTrack)

        beatFill = SKSpriteNode(color: Theme.safe, size: CGSize(width: 212, height: 8))
        beatFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        beatFill.position = CGPoint(x: -106, y: 0)
        beatTrack.addChild(beatFill)

        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 34
        scoreLabel.fontColor = Theme.cream
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = .zero
        scoreLabel.text = "0"
        scoreLabel.isHidden = true
        hud.addChild(scoreLabel)
    }

    private func layoutHUD() {
        hud.position = CGPoint(x: size.width / 2, y: size.height - 78)
        scoreLabel.position = CGPoint(x: 0, y: 28)
        beatTrack.position = CGPoint(x: 0, y: -8)
    }

    // MARK: - Menu / Game flow

    private func showMenu(animated: Bool) {
        state = .menu
        overlay.removeAllChildren()
        world.removeAllChildren()
        character?.removeFromParent()
        arrow?.removeFromParent()
        beatTrack.isHidden = true
        scoreLabel.isHidden = true
        layoutHUD()
        rebuildStaircase(preview: true)
        spawnCharacter(idle: true)

        overlay.zPosition = 80
        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.28), size: size)
        dim.anchorPoint = .zero
        overlay.addChild(dim)

        let title = SKSpriteNode(texture: PixelArt.titleBanner())
        title.setScale(7)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        overlay.addChild(title)

        let subtitle = makeLabel("TAP LEFT OR RIGHT\nMATCH THE STEP\nMISS OR WAIT AND YOU FALL", size: 14, color: Theme.gold)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        overlay.addChild(subtitle)

        let play = makeLabel("TAP TO CLIMB", size: 22, color: Theme.cream)
        play.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        play.name = "play"
        overlay.addChild(play)
        play.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.7),
            .fadeAlpha(to: 1, duration: 0.7)
        ])))

        let bestLabel = makeLabel("BEST \(best)", size: 16, color: Theme.cream)
        bestLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.16)
        overlay.addChild(bestLabel)
    }

    private func startGame() {
        overlay.removeAllChildren()
        world.removeAllChildren()
        character?.removeFromParent()
        arrow?.removeFromParent()

        score = 0
        currentIndex = 0
        isBusy = false
        state = .playing
        scoreLabel.text = "0"
        scoreLabel.isHidden = false
        beatTrack.isHidden = false
        layoutHUD()
        rebuildStaircase(preview: false)
        spawnCharacter(idle: false)
        resetBeat()
        Haptics.tap()
    }

    private func rebuildStaircase(preview: Bool) {
        steps.removeAll()
        world.position = CGPoint(x: size.width / 2, y: homeY)
        var x: CGFloat = 0
        addStep(x: x, worldY: 0, cracked: false)
        for i in 1..<8 {
            let side = pickNextSide(from: x)
            x = clampedX(x + side.sign * Layout.lateral)
            let cracked = !preview && i > 2 && Int.random(in: 0...10) == 0
            addStep(x: x, worldY: CGFloat(i) * Layout.stepSpacing, cracked: cracked)
        }
        if steps.count > 1 {
            nextSide = steps[1].x >= steps[0].x ? .right : .left
        }
    }

    private func addStep(x: CGFloat, worldY: CGFloat, cracked: Bool) {
        let node = SKSpriteNode(texture: PixelArt.step(cracked: cracked))
        node.setScale(Layout.artScale)
        node.position = CGPoint(x: x, y: worldY)
        node.zPosition = 2
        world.addChild(node)
        steps.append(Step(node: node, x: x, worldY: worldY, cracked: cracked))
    }

    private func spawnCharacter(idle: Bool) {
        character = SKSpriteNode(texture: PixelArt.heroIdle)
        character.setScale(Layout.heroScale)
        character.zPosition = 10
        character.position = CGPoint(x: size.width / 2 + currentX, y: homeY + stepHeight / 2 + heroHeight / 2 - 6)
        addChild(character)

        arrow = SKSpriteNode(texture: PixelArt.arrow(left: nextSide == .left))
        arrow.setScale(4)
        arrow.zPosition = 12
        addChild(arrow)
        updateArrow()

        if idle {
            character.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 6, duration: 0.45),
                .moveBy(x: 0, y: -6, duration: 0.45)
            ])))
        }
    }

    private var currentX: CGFloat {
        guard steps.indices.contains(currentIndex) else { return 0 }
        return steps[currentIndex].x
    }

    private func pickNextSide(from x: CGFloat) -> Side {
        let leftX = clampedX(x - Layout.lateral)
        let rightX = clampedX(x + Layout.lateral)
        if x <= leftX + 1 { return .right }
        if x >= rightX - 1 { return .left }
        return Bool.random() ? .left : .right
    }

    private func clampedX(_ x: CGFloat) -> CGFloat {
        let limit = size.width * 0.32
        return min(max(x, -limit), limit)
    }

    private func updateArrow() {
        guard let arrow, let character else { return }
        arrow.texture = PixelArt.arrow(left: nextSide == .left)
        arrow.position = CGPoint(
            x: character.position.x + nextSide.sign * 42,
            y: character.position.y + 58
        )
        arrow.alpha = score >= 18 ? 0 : (score >= 10 ? 0.35 : 1)
        arrow.isHidden = state != .playing
    }

    private func resetBeat() {
        beatMax = max(0.42, 1.32 - Double(score) * 0.028)
        beatRemaining = beatMax
        beatFill.size.width = 212
        beatFill.color = Theme.safe
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch state {
        case .menu:
            startGame()
        case .gameOver:
            showMenu(animated: true)
        case .playing:
            guard !isBusy else { return }
            let tapped: Side = location.x < size.width / 2 ? .left : .right
            attemptJump(tapped)
        }
    }

    private func attemptJump(_ tapped: Side) {
        guard steps.indices.contains(currentIndex + 1) else { return }

        if tapped != nextSide {
            fail(reason: "WRONG STEP")
            return
        }

        isBusy = true
        Haptics.tap()
        let next = steps[currentIndex + 1]
        let start = character.position
        let end = CGPoint(
            x: size.width / 2 + next.x,
            y: homeY + stepHeight / 2 + heroHeight / 2 - 6
        )
        let worldStart = world.position
        let worldEnd = CGPoint(x: size.width / 2, y: homeY - next.worldY)

        character.texture = PixelArt.heroJump
        character.xScale = tapped == .left ? -Layout.heroScale : Layout.heroScale
        character.yScale = Layout.heroScale

        let duration: TimeInterval = 0.16
        let hop = SKAction.customAction(withDuration: duration) { [weak self] node, t in
            guard let self else { return }
            let p = t / CGFloat(duration)
            let lift = sin(p * .pi) * 46
            node.position = CGPoint(
                x: start.x + (end.x - start.x) * p,
                y: start.y + (end.y - start.y) * p + lift
            )
            self.world.position = CGPoint(
                x: worldStart.x,
                y: worldStart.y + (worldEnd.y - worldStart.y) * p
            )
            self.updateArrow()
        }

        character.run(hop) { [weak self] in
            self?.land(on: next)
        }
    }

    private func land(on step: Step) {
        character.texture = PixelArt.heroIdle
        character.position = CGPoint(
            x: size.width / 2 + step.x,
            y: homeY + stepHeight / 2 + heroHeight / 2 - 6
        )
        currentIndex += 1
        score += 1
        scoreLabel.text = "\(score)"
        Haptics.land()
        puff()

        if step.cracked {
            fail(reason: "CRACKED STEP")
            return
        }

        let last = steps.last!
        var newX = last.x + pickNextSide(from: last.x).sign * Layout.lateral
        newX = clampedX(newX)
        if steps.count >= 2 {
            let prev = steps[steps.count - 2].x
            if abs(newX - last.x) < 8 {
                newX = clampedX(last.x + (last.x >= prev ? -Layout.lateral : Layout.lateral))
            }
        }
        addStep(x: newX, worldY: last.worldY + Layout.stepSpacing, cracked: score > 8 && Int.random(in: 0...12) == 0)

        if let upcoming = steps[safe: currentIndex + 1] {
            nextSide = upcoming.x >= step.x ? .right : .left
        }
        updateArrow()
        resetBeat()
        isBusy = false

        if currentIndex > 4 {
            let stale = steps[currentIndex - 4]
            stale.node.run(.fadeOut(withDuration: 0.2)) {
                stale.node.removeFromParent()
            }
        }
    }

    private func fail(reason: String) {
        guard state == .playing else { return }
        state = .gameOver
        isBusy = true
        beatTrack.isHidden = true
        arrow.isHidden = true
        Haptics.fail()

        character.removeAllActions()
        character.texture = PixelArt.heroFall
        character.run(.group([
            .moveBy(x: nextSide.opposite.sign * 40, y: -260, duration: 0.55),
            .rotate(byAngle: nextSide == .left ? 2.6 : -2.6, duration: 0.55),
            .fadeAlpha(to: 0.15, duration: 0.55)
        ]))

        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "bestScore")
        }

        overlay.removeAllChildren()
        overlay.zPosition = 80
        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.45), size: size)
        dim.anchorPoint = .zero
        overlay.addChild(dim)

        let title = makeLabel(reason, size: 28, color: Theme.danger)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        overlay.addChild(title)

        let scored = makeLabel("STEPS \(score)", size: 22, color: Theme.cream)
        scored.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        overlay.addChild(scored)

        let bestLabel = makeLabel("BEST \(best)", size: 16, color: Theme.gold)
        bestLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.46)
        overlay.addChild(bestLabel)

        let again = makeLabel("TAP TO RETRY", size: 18, color: Theme.cream)
        again.position = CGPoint(x: size.width / 2, y: size.height * 0.32)
        overlay.addChild(again)
        again.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 0.6),
            .fadeAlpha(to: 1, duration: 0.6)
        ])))
    }

    private func puff() {
        for i in 0..<6 {
            let bit = SKSpriteNode(color: Theme.stepHighlight, size: CGSize(width: 6, height: 6))
            bit.position = CGPoint(x: character.position.x + CGFloat.random(in: -18...18), y: character.position.y - 28)
            bit.zPosition = 9
            addChild(bit)
            bit.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(i - 3) * 8, y: CGFloat.random(in: 8...22), duration: 0.28),
                    .fadeOut(withDuration: 0.28)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime }
        let dt = currentTime - lastUpdate
        lastUpdate = currentTime
        layoutHUD()

        guard state == .playing, !isBusy else { return }
        beatRemaining -= dt
        let pct = max(0, CGFloat(beatRemaining / beatMax))
        beatFill.size.width = 212 * pct
        beatFill.color = pct < 0.28 ? Theme.danger : (pct < 0.55 ? Theme.gold : Theme.safe)
        if beatRemaining <= 0 {
            fail(reason: "TOO SLOW")
        }
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.numberOfLines = 0
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = self.size.width - 48
        return label
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
