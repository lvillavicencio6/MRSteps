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
        let node: SKNode
        let block: SKSpriteNode
        let shade: SKSpriteNode
        let x: CGFloat
        let index: Int
    }

    private var state: State = .menu
    private var world = SKNode()
    private var hud = SKNode()
    private var character: SKSpriteNode!
    private var heroShadow: SKSpriteNode!
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
    private var now: TimeInterval = 0
    private var cameraZ: CGFloat = 0
    private var camX: CGFloat = 0
    private var hopLift: CGFloat = 0
    private var idleBob = false

    private var homeY: CGFloat { size.height * 0.30 }
    private var heroHeight: CGFloat { 18 * Layout.heroScale }
    private var didSetup = false

    override func didMove(to view: SKView) {
        backgroundColor = Theme.skyTop
        anchorPoint = .zero
        isUserInteractionEnabled = true
        guard !didSetup else {
            buildBackground()
            layoutWorld()
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
        world.position = CGPoint(x: size.width / 2, y: homeY)
        layoutWorld()
        placeHero()
        if state == .menu {
            showMenu(animated: false)
        }
    }

    // MARK: - Setup

    private func buildBackground() {
        childNode(withName: "sky")?.removeFromParent()
        childNode(withName: "vignette")?.removeFromParent()

        let sky = SKNode()
        sky.name = "sky"
        sky.zPosition = -20
        insertChild(sky, at: 0)

        let wash = SKSpriteNode(texture: PixelArt.skyGradient(size: CGSize(width: 8, height: 64)))
        wash.size = size
        wash.anchorPoint = .zero
        wash.zPosition = -2
        sky.addChild(wash)

        let glow = SKSpriteNode(color: Theme.moonGlow, size: CGSize(width: 220, height: 220))
        glow.alpha = 0.16
        glow.position = CGPoint(x: size.width * 0.78, y: size.height * 0.80)
        glow.zPosition = -1
        sky.addChild(glow)
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.10, duration: 2.4),
            .fadeAlpha(to: 0.20, duration: 2.4)
        ])))

        let moon = SKSpriteNode(texture: PixelArt.moon)
        moon.setScale(5)
        moon.position = CGPoint(x: size.width * 0.78, y: size.height * 0.80)
        moon.zPosition = 0
        sky.addChild(moon)

        for i in 0..<28 {
            let big = i % 5 == 0
            let star = SKSpriteNode(color: Theme.star, size: CGSize(width: big ? 4 : 2, height: big ? 4 : 2))
            star.position = CGPoint(
                x: CGFloat((i * 53 + 19) % max(Int(size.width), 1)),
                y: size.height * (0.42 + CGFloat((i * 17) % 52) / 100)
            )
            star.alpha = 0.25 + CGFloat(i % 5) * 0.14
            star.zPosition = -1
            sky.addChild(star)
            star.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.12, duration: 0.7 + Double(i % 4) * 0.25),
                .fadeAlpha(to: 0.95, duration: 0.7 + Double(i % 3) * 0.25)
            ])))
        }

        for i in 0..<5 {
            let cloud = SKSpriteNode(texture: PixelArt.cloud())
            cloud.setScale(CGFloat(3 + i % 3))
            cloud.alpha = 0.28 + CGFloat(i % 3) * 0.08
            cloud.position = CGPoint(
                x: CGFloat(i) * 160 - 50,
                y: size.height * (0.52 + CGFloat(i % 3) * 0.1)
            )
            cloud.zPosition = 1
            sky.addChild(cloud)
            let dx = size.width + 260
            cloud.run(.repeatForever(.sequence([
                .moveBy(x: dx, y: 12, duration: 36 + Double(i) * 5),
                .moveBy(x: -dx, y: -12, duration: 0)
            ])))
        }

        let mist = SKSpriteNode(color: Theme.mist, size: CGSize(width: size.width, height: size.height * 0.28))
        mist.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        mist.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        mist.alpha = 0.10
        mist.zPosition = 2
        sky.addChild(mist)

        let shaft = SKSpriteNode(color: Theme.moonGlow, size: CGSize(width: size.width * 0.55, height: size.height * 0.9))
        shaft.alpha = 0.05
        shaft.position = CGPoint(x: size.width * 0.62, y: size.height * 0.55)
        shaft.zRotation = -0.18
        shaft.zPosition = 3
        sky.addChild(shaft)

        let vignette = SKSpriteNode(texture: PixelArt.vignette(size: CGSize(width: 32, height: 48)))
        vignette.name = "vignette"
        vignette.size = size
        vignette.anchorPoint = .zero
        vignette.zPosition = 40
        addChild(vignette)
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
        childNode(withName: "vignette")?.position = .zero
        if let vignette = childNode(withName: "vignette") as? SKSpriteNode {
            vignette.size = size
        }
    }

    // MARK: - Menu / Game flow

    private func showMenu(animated: Bool) {
        state = .menu
        overlay.removeAllChildren()
        world.removeAllChildren()
        character?.removeFromParent()
        heroShadow?.removeFromParent()
        arrow?.removeFromParent()
        beatTrack.isHidden = true
        scoreLabel.isHidden = true
        hopLift = 0
        layoutHUD()
        rebuildStaircase()
        spawnCharacter(idle: true)

        overlay.zPosition = 80
        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.22), size: size)
        dim.anchorPoint = .zero
        overlay.addChild(dim)

        let title = SKSpriteNode(texture: PixelArt.titleBanner())
        title.setScale(7)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.74)
        overlay.addChild(title)

        let subtitle = makeLabel("TAP LEFT OR RIGHT\nMATCH THE STEP\nMISS OR WAIT AND YOU FALL", size: 14, color: Theme.gold)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        overlay.addChild(subtitle)

        let play = makeLabel("TAP TO CLIMB", size: 22, color: Theme.cream)
        play.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        play.name = "play"
        overlay.addChild(play)
        play.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.7),
            .fadeAlpha(to: 1, duration: 0.7)
        ])))

        let bestLabel = makeLabel("BEST \(best)", size: 16, color: Theme.cream)
        bestLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        overlay.addChild(bestLabel)
    }

    private func startGame() {
        overlay.removeAllChildren()
        world.removeAllChildren()
        character?.removeFromParent()
        heroShadow?.removeFromParent()
        arrow?.removeFromParent()

        score = 0
        currentIndex = 0
        isBusy = false
        hopLift = 0
        state = .playing
        scoreLabel.text = "0"
        scoreLabel.isHidden = false
        beatTrack.isHidden = false
        layoutHUD()
        rebuildStaircase()
        spawnCharacter(idle: false)
        resetBeat()
        Haptics.tap()
    }

    private func rebuildStaircase() {
        steps.removeAll()
        world.position = CGPoint(x: size.width / 2, y: homeY)
        cameraZ = 0
        camX = 0
        var x: CGFloat = 0
        addStep(x: x)
        for _ in 1..<16 {
            let side = pickNextSide(from: x)
            x = clampedX(x + side.sign * Layout.lateral)
            addStep(x: x)
        }
        if steps.count > 1 {
            nextSide = steps[1].x >= steps[0].x ? .right : .left
        }
        layoutWorld()
    }

    private func addStep(x: CGFloat) {
        let index = steps.count
        let node = SKNode()
        node.zPosition = 2

        let shade = SKSpriteNode(texture: PixelArt.shadow)
        shade.zPosition = 0
        shade.position = CGPoint(x: 10, y: -18)
        node.addChild(shade)

        let block = SKSpriteNode(texture: PixelArt.step)
        block.anchorPoint = CGPoint(x: 0.5, y: 0.38)
        block.zPosition = 1
        node.addChild(block)

        world.addChild(node)
        steps.append(Step(node: node, block: block, shade: shade, x: x, index: index))
    }

    private func spawnCharacter(idle: Bool) {
        heroShadow = SKSpriteNode(texture: PixelArt.shadow)
        heroShadow.zPosition = 9
        heroShadow.alpha = 0.9
        addChild(heroShadow)

        character = SKSpriteNode(texture: PixelArt.heroIdle)
        character.setScale(Layout.heroScale)
        character.zPosition = 30
        addChild(character)

        arrow = SKSpriteNode(texture: PixelArt.arrow(left: nextSide == .left))
        arrow.setScale(4)
        arrow.zPosition = 32
        addChild(arrow)

        idleBob = idle
        placeHero()
        layoutWorld()
        updateArrow()
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
        let limit = Layout.lateral * 2.4
        return min(max(x, -limit), limit)
    }

    private func project(index: CGFloat, x: CGFloat) -> (pos: CGPoint, scale: CGFloat, fog: CGFloat, z: CGFloat) {
        let relZ = index - cameraZ
        let depth = max(0.42, 1 + relZ * Layout.depth)
        let persp = 1 / depth
        let pos = CGPoint(
            x: (x - camX) * persp,
            y: relZ * Layout.stepSpacing * persp
        )
        let scale = Layout.artScale * persp * 1.08
        let fog = max(0.18, min(1, 1.05 - relZ * 0.065))
        let z = 20 - relZ * 2
        return (pos, scale, fog, z)
    }

    private func layoutWorld() {
        for step in steps {
            let p = project(index: CGFloat(step.index), x: step.x)
            step.node.position = p.pos
            step.node.zPosition = p.z
            step.node.alpha = step.node.parent == nil ? 0 : p.fog
            step.node.isHidden = (CGFloat(step.index) - cameraZ) < -1.2

            let isNext = state == .playing && step.index == currentIndex + 1
            let pulse = isNext ? 1 + 0.045 * sin(now * 7) : 1
            step.block.setScale(p.scale * pulse)
            step.shade.setScale(p.scale * 0.95)
            step.shade.alpha = 0.55 * p.fog
            step.shade.position = CGPoint(x: 8 * p.scale / Layout.artScale, y: -16 * p.scale / Layout.artScale)

            if isNext {
                step.block.color = Theme.gold
                step.block.colorBlendFactor = 0.18
            } else {
                step.block.color = Theme.skyMid
                step.block.colorBlendFactor = (1 - p.fog) * 0.85
            }
        }
        placeHero()
        updateArrow()
    }

    private func placeHero() {
        guard let character else { return }
        let bob = idleBob ? sin(now * 2.4) * 6 : 0
        let standY = homeY + heroHeight * 0.36 + hopLift + bob
        character.position = CGPoint(x: size.width / 2, y: standY)
        heroShadow?.position = CGPoint(x: size.width / 2 + 6, y: homeY + 6)
        let apex = min(1, hopLift / 36)
        heroShadow?.setScale(1.15 - apex * 0.45)
        heroShadow?.alpha = 0.85 - apex * 0.45
    }

    private func updateArrow() {
        guard let arrow, let character else { return }
        arrow.texture = PixelArt.arrow(left: nextSide == .left)
        arrow.position = CGPoint(
            x: character.position.x + nextSide.sign * 46,
            y: character.position.y + 54
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
        let fromZ = cameraZ
        let fromX = camX
        character.removeAllActions()
        character.texture = PixelArt.heroJump
        character.xScale = tapped == .left ? -Layout.heroScale : Layout.heroScale
        character.yScale = Layout.heroScale

        let duration: TimeInterval = 0.18
        let hop = SKAction.customAction(withDuration: duration) { [weak self] _, t in
            guard let self else { return }
            let p = t / CGFloat(duration)
            let ease = 1 - pow(1 - p, 2)
            self.cameraZ = fromZ + (CGFloat(next.index) - fromZ) * ease
            self.camX = fromX + (next.x - fromX) * ease
            self.hopLift = sin(p * .pi) * 38
            self.layoutWorld()
        }

        character.run(hop) { [weak self] in
            self?.land(on: next)
        }
    }

    private func land(on step: Step) {
        hopLift = 0
        cameraZ = CGFloat(step.index)
        camX = step.x
        character.texture = PixelArt.heroIdle
        character.xScale = (nextSide == .left ? -1 : 1) * Layout.heroScale
        character.yScale = Layout.heroScale
        character.run(.sequence([
            .group([
                .scaleX(to: (nextSide == .left ? -1 : 1) * Layout.heroScale * 1.12, duration: 0.06),
                .scaleY(to: Layout.heroScale * 0.86, duration: 0.06)
            ]),
            .group([
                .scaleX(to: (nextSide == .left ? -1 : 1) * Layout.heroScale, duration: 0.08),
                .scaleY(to: Layout.heroScale, duration: 0.08)
            ])
        ]))

        currentIndex += 1
        score += 1
        scoreLabel.text = "\(score)"
        Haptics.land()
        puff()

        let last = steps.last!
        var newX = last.x + pickNextSide(from: last.x).sign * Layout.lateral
        newX = clampedX(newX)
        if steps.count >= 2 {
            let prev = steps[steps.count - 2].x
            if abs(newX - last.x) < 8 {
                newX = clampedX(last.x + (last.x >= prev ? -Layout.lateral : Layout.lateral))
            }
        }
        addStep(x: newX)

        if let upcoming = steps[safe: currentIndex + 1] {
            nextSide = upcoming.x >= step.x ? .right : .left
        }
        layoutWorld()
        resetBeat()
        isBusy = false

        if currentIndex > 3 {
            let stale = steps[currentIndex - 3]
            stale.node.run(.fadeOut(withDuration: 0.22)) {
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
            .moveBy(x: nextSide.opposite.sign * 28, y: -280, duration: 0.6),
            .scale(to: Layout.heroScale * 0.35, duration: 0.6),
            .rotate(byAngle: nextSide == .left ? 2.6 : -2.6, duration: 0.6),
            .fadeAlpha(to: 0.12, duration: 0.6)
        ]))
        heroShadow?.run(.fadeOut(withDuration: 0.25))

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
        for i in 0..<8 {
            let bit = SKSpriteNode(color: Theme.stepHighlight, size: CGSize(width: 5, height: 5))
            bit.position = CGPoint(x: character.position.x + CGFloat.random(in: -16...16), y: homeY + 10)
            bit.zPosition = 28
            addChild(bit)
            bit.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(i - 4) * 7, y: CGFloat.random(in: 10...26), duration: 0.3),
                    .fadeOut(withDuration: 0.3),
                    .scale(to: 0.2, duration: 0.3)
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
        now = currentTime
        layoutHUD()
        if state != .gameOver {
            layoutWorld()
        }

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
