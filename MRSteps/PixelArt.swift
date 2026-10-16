import SpriteKit
import UIKit

enum PixelArt {
    static func texture(cols: Int, rows: Int, pixels: [String], colors: [Character: SKColor]) -> SKTexture {
        let size = CGSize(width: cols, height: rows)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            for y in 0..<rows {
                let line = pixels[y]
                for x in 0..<cols {
                    let ch = line[line.index(line.startIndex, offsetBy: x)]
                    guard ch != ".", let color = colors[ch] else { continue }
                    ctx.cgContext.setFillColor(color.cgColor)
                    ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    static let heroIdle = texture(cols: 16, rows: 18, pixels: [
        "......3333......",
        ".....333333.....",
        "....33333333....",
        "....22222222....",
        "....2E2222E2....",
        "....22266222....",
        ".....222222.....",
        "....44444444....",
        "...4444444444...",
        "...44.4444.44...",
        "...44.4444.44...",
        "....55555555....",
        "....55....55....",
        "....55....55....",
        "....77....77....",
        "....77....77....",
        "...777....777...",
        "................"
    ], colors: heroColors)

    static let heroJump = texture(cols: 16, rows: 18, pixels: [
        "......3333......",
        ".....333333.....",
        "....33333333....",
        "....22222222....",
        "....2E2222E2....",
        "....22266222....",
        ".....222222.....",
        "....44444444....",
        "...4444444444...",
        "..44..4444..44..",
        "..44..4444..44..",
        "....55555555....",
        "...55......55...",
        "..55........55..",
        "..77........77..",
        ".777........777.",
        "................",
        "................"
    ], colors: heroColors)

    static let heroFall = texture(cols: 16, rows: 18, pixels: [
        "................",
        "....3333........",
        "...333333.......",
        "..22222222......",
        "..2E2222E2......",
        "..22266222......",
        "...222222.......",
        "..44444444......",
        ".4444444444.....",
        "44..4444..44....",
        "....555555......",
        "...55....55.....",
        "..55......55....",
        ".77........77...",
        "77..........77..",
        "................",
        "................",
        "................"
    ], colors: heroColors)

    private static let heroColors: [Character: SKColor] = [
        "3": Theme.cap,
        "2": Theme.skin,
        "E": Theme.ink,
        "6": SKColor(red: 0.55, green: 0.28, blue: 0.22, alpha: 1),
        "4": Theme.shirt,
        "5": Theme.pants,
        "7": Theme.shoe
    ]

    static let step = makeIsometricStep()
    static let shadow = makeShadow()
    static let moon = makeMoon()

    static func cloud() -> SKTexture {
        texture(cols: 22, rows: 8, pixels: [
            "......111111......111.",
            "....1111111111...11111",
            "...111111111111.111111",
            "..11111111111111111111",
            ".111111111111111111111",
            "1111111111111111111111",
            ".11111111111111111111.",
            "..1111111..11111111..."
        ], colors: ["1": SKColor(white: 0.92, alpha: 0.82)])
    }

    static func arrow(left: Bool) -> SKTexture {
        let pixels = left ? [
            "....1.....",
            "...11.....",
            "..11111111",
            ".111111111",
            "1111111111",
            ".111111111",
            "..11111111",
            "...11.....",
            "....1.....",
            ".........."
        ] : [
            ".....1....",
            ".....11...",
            "11111111..",
            "111111111.",
            "1111111111",
            "111111111.",
            "11111111..",
            ".....11...",
            ".....1....",
            ".........."
        ]
        return texture(cols: 10, rows: 10, pixels: pixels, colors: ["1": Theme.gold])
    }

    static func titleBanner() -> SKTexture {
        let word = "MR STEPS"
        let glyphW = 5
        let glyphH = 5
        let gap = 1
        let cols = word.count * (glyphW + gap) - gap + 4
        let rows = glyphH + 4
        var grid = Array(repeating: Array(repeating: Character("."), count: cols), count: rows)

        func stamp(_ ch: Character, at originX: Int) {
            guard let g = font[ch] else { return }
            for y in 0..<glyphH {
                for x in 0..<glyphW {
                    if g[y][g[y].index(g[y].startIndex, offsetBy: x)] == "1" {
                        grid[y + 2][originX + x] = "1"
                    }
                }
            }
        }

        var ox = 2
        for ch in word {
            stamp(ch, at: ox)
            ox += glyphW + gap
        }

        return texture(cols: cols, rows: rows, pixels: grid.map { String($0) }, colors: ["1": Theme.cream])
    }

    static func skyGradient(size: CGSize) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let colors = [Theme.skyTop.cgColor, Theme.skyMid.cgColor, Theme.skyBottom.cgColor] as CFArray
            var locations: [CGFloat] = [0, 0.48, 1]
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: &locations) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func vignette(size: CGSize) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [
                SKColor.clear.cgColor,
                SKColor(white: 0, alpha: 0.08).cgColor,
                SKColor(white: 0, alpha: 0.55).cgColor
            ] as CFArray
            var locations: [CGFloat] = [0.35, 0.7, 1]
            guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: &locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: hypot(size.width, size.height) * 0.62,
                options: .drawsAfterEndLocation
            )
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func makeIsometricStep() -> SKTexture {
        let sx = 16
        let sy = 9
        let sz = 16
        let pad = 2
        let width = sx + sz + pad * 2
        let pyMin = 1 - sy
        let pyMax = (sx + sz - 2) / 2
        let originRow = pyMax + pad
        let height = originRow - pyMin + pad + 1
        var pix = Array(repeating: Array(repeating: Optional<SKColor>.none, count: width), count: height)
        let ox = sz + pad - 1

        func put(_ x: Int, _ y: Int, _ color: SKColor) {
            guard y >= 0, y < height, x >= 0, x < width else { return }
            pix[y][x] = color
        }

        for z in (0..<sz).reversed() {
            for x in 0..<sx {
                for y in 0..<sy {
                    let surface = x == 0 || x == sx - 1 || y == 0 || y == sy - 1 || z == 0 || z == sz - 1
                    guard surface else { continue }

                    let color: SKColor
                    if y == sy - 1 {
                        let grout = x % 4 == 0 || z % 4 == 0
                        let rim = x + z < 6
                        if grout {
                            color = Theme.stepGrout
                        } else if rim {
                            color = Theme.stepHighlight
                        } else if (x + z) % 2 == 0 {
                            color = Theme.stepTop
                        } else {
                            color = SKColor(red: 0.90, green: 0.60, blue: 0.36, alpha: 1)
                        }
                    } else if x == sx - 1 {
                        color = y < 3 ? Theme.stepMid : Theme.stepSide
                    } else if z == sz - 1 {
                        color = y < 3 ? Theme.stepSide : Theme.stepDark
                    } else if x == 0 {
                        color = Theme.stepDark
                    } else {
                        color = Theme.stepDark
                    }

                    let px = ox + x - z
                    let py = (x + z) / 2 - y
                    let row = originRow - py
                    put(px, row, color)
                }
            }
        }

        for y in 0..<height {
            for x in 0..<width {
                guard pix[y][x] != nil else { continue }
                var edge = false
                for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                    let nx = x + dx
                    let ny = y + dy
                    if nx < 0 || ny < 0 || nx >= width || ny >= height || pix[ny][nx] == nil {
                        edge = true
                        break
                    }
                }
                if edge {
                    pix[y][x] = Theme.ink
                }
            }
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            for y in 0..<height {
                for x in 0..<width {
                    guard let color = pix[y][x] else { continue }
                    ctx.cgContext.setFillColor(color.cgColor)
                    ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private static func makeShadow() -> SKTexture {
        texture(cols: 18, rows: 8, pixels: [
            "..................",
            ".....11111111.....",
            "...111111111111...",
            "..11111111111111..",
            "...111111111111...",
            ".....11111111.....",
            "..................",
            ".................."
        ], colors: ["1": Theme.stepShadow])
    }

    private static func makeMoon() -> SKTexture {
        texture(cols: 16, rows: 16, pixels: [
            ".....111111.....",
            "...1111111111...",
            "..111111111111..",
            ".11111111111111.",
            ".11111111111111.",
            "1111111111111111",
            "11111..111111111",
            "1111....11111111",
            "1111....11111111",
            "11111..111111111",
            "1111111111111111",
            ".11111111111111.",
            ".11111111111111.",
            "..111111111111..",
            "...1111111111...",
            ".....111111....."
        ], colors: ["1": Theme.moon])
    }

    private static let font: [Character: [String]] = [
        "M": ["1...1", "11.11", "1.1.1", "1...1", "1...1"],
        "R": ["1111.", "1...1", "1111.", "1..1.", "1...1"],
        " ": [".....", ".....", ".....", ".....", "....."],
        "S": [".1111", "1....", ".111.", "....1", "1111."],
        "T": ["11111", "..1..", "..1..", "..1..", "..1.."],
        "E": ["11111", "1....", "1111.", "1....", "11111"],
        "P": ["1111.", "1...1", "1111.", "1....", "1...."]
    ]
}
