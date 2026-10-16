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

    static func step(cracked: Bool = false) -> SKTexture {
        var rows: [String] = []
        let w = Layout.stepPixelW
        let h = Layout.stepPixelH
        for y in 0..<h {
            var line = ""
            for x in 0..<w {
                let isEdge = x == 0 || y == 0 || x == w - 1 || y == h - 1
                let grout = x % 8 == 0 || y == 4 || y == 9
                let crack = cracked && ((x + y * 3) % 11 == 0) && y > 2 && y < 12
                if isEdge || crack {
                    line.append("D")
                } else if y == 1 {
                    line.append("H")
                } else if grout {
                    line.append("G")
                } else if y < 5 {
                    line.append("T")
                } else if x > w - 5 {
                    line.append("D")
                } else {
                    line.append("M")
                }
            }
            rows.append(line)
        }
        return texture(cols: w, rows: h, pixels: rows, colors: [
            "H": Theme.stepHighlight,
            "T": Theme.stepTop,
            "M": Theme.stepMid,
            "G": Theme.stepGrout,
            "D": Theme.stepDark
        ])
    }

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
