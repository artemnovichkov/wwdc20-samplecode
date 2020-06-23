/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Value for generating pencilkit text.
*/

import PencilKit

struct TextGenerator {
    let lowercaseDrawings: [PKDrawing]
    let uppercaseDrawings: [PKDrawing]

    // The number of strokes in each letter of the alphabet, for upper/lowercase assets.
    static let lowercaseStrokeCount = [1, 1, 1, 1, 1, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1]
    static let uppercaseStrokeCount = [3, 2, 1, 2, 4, 3, 2, 3, 3, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 1]
    
    static let templateColor = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    
    init() {
        // Get the lowercase and uppercase alphabet drawings.
        guard let lowercaseData = NSDataAsset(name: "lowercase")?.data, let lowercase = try? PKDrawing(data: lowercaseData),
              let uppercaseData = NSDataAsset(name: "uppercase")?.data, let uppercase = try? PKDrawing(data: uppercaseData) else {
            fatalError("Could not load font drawing assets.")
        }
            
        // Split the drawings up into individual letters.
        lowercaseDrawings = TextGenerator.loadAndSplitDrawing(lowercase, strokeCount: TextGenerator.lowercaseStrokeCount)
        uppercaseDrawings = TextGenerator.loadAndSplitDrawing(uppercase, strokeCount: TextGenerator.uppercaseStrokeCount)
    }
    
    static var pencilKitLigature: PKDrawing = {
        // Get the PencilKit ligature drawing.
        guard let ligatureData = NSDataAsset(name: "pencilkit")?.data, var drawing = try? PKDrawing(data: ligatureData) else {
            fatalError("Could not load PencilKit ligature drawing asset.")
        }
        drawing.strokes = drawing.strokes.map { stroke -> PKStroke in
            // Modify the strokes to have the correct color.
            var stroke = stroke
            stroke.ink = PKInk(.pen, color: TextGenerator.templateColor)
            return stroke
        }
        return drawing
    }()
    
    func letter(ascii: UInt8) -> PKDrawing? {
        if ascii >= 97 && ascii <= 122 {
            return lowercaseDrawings[Int(ascii) - 97]
        } else if ascii >= 65 && ascii <= 90 {
            return uppercaseDrawings[Int(ascii) - 65]
        }
        return nil
    }
    
    func synthesizeTextDrawing(text: String, practiceScale: CGFloat, lineWidth: CGFloat) -> PKDrawing {
        // Special case the PencilKit ligature.
        if text.lowercased() == "pencilkit" {
            return TextGenerator.pencilKitLigature
        }
        
        var textDrawing = PKDrawing()
        let textMargin: CGFloat = 100
        let lineHeight: CGFloat = 80 * practiceScale
        let spaceWidth: CGFloat = 40 * practiceScale
        let letterSpacing: CGFloat = 2
        var letterPosition = CGPoint(x: textMargin, y: 200)
        var didJustWrap = false
        
        // Layout the text by words.
        text.enumerateSubstrings(in: text.startIndex..., options: .byWords) { (word, _, _, _) in
            guard let word = word else { return }
            
            // Calculate the word width.
            let wordLength = word.reduce(CGFloat(0)) {
                // Ensure it is an ASCII character.
                guard let character = $1.asciiValue else { return $0 }
                guard let letter = self.letter(ascii: character) else { return $0 }
                return $0 + letter.bounds.width * practiceScale + letterSpacing
            }
            
            // Should this word wrap?
            if !didJustWrap && letterPosition.x + wordLength + textMargin > lineWidth {
                letterPosition.x = textMargin
                letterPosition.y += lineHeight
                didJustWrap = true
            } else {
                didJustWrap = false
            }
            
            // Generate the letter.
            for character in word {
                // Ensure it is an ASCII character.
                guard let character = character.asciiValue else { continue }
                guard var letter = self.letter(ascii: character) else { continue }
                
                // Get the letter and align it.
                letter.transform(using: CGAffineTransform(scaleX: practiceScale, y: practiceScale)
                      .concatenating(CGAffineTransform(translationX: letterPosition.x, y: letterPosition.y)))
                textDrawing.append(letter)
                
                // Move for the next letter.
                letterPosition.x += letter.bounds.width + letterSpacing
            }
            
            // Add a space.
            letterPosition.x += spaceWidth
        }
        
        return textDrawing
    }
    
    // MARK: - Font loading
    
    static func loadAndSplitDrawing(_ drawing: PKDrawing, strokeCount: [Int]) -> [PKDrawing] {
        // Adjust the strokes to look better for a template.
        let adjustedStrokes = drawing.strokes.map { stroke -> PKStroke in
            var stroke = stroke
            // Adjust the stroke ink to be grey.
            stroke.ink = PKInk(.pen, color: TextGenerator.templateColor)
            
            // Adjust the stroke widths to be more uniform.
            let newPoints = stroke.path.indices.compactMap { index -> PKStrokePoint? in
                let point = stroke.path[index]
                let adjustedPoint = PKStrokePoint(
                    location: point.location,
                    timeOffset: point.timeOffset,
                    size: CGSize(width: point.size.width * 0.8, height: point.size.height * 0.8),
                    opacity: point.opacity,
                    force: point.force,
                    azimuth: point.azimuth,
                    altitude: point.altitude)
                return adjustedPoint
            }
            stroke.path = PKStrokePath(controlPoints: newPoints, creationDate: stroke.path.creationDate)
            
            return stroke
        }
        
        // Normalize the bounds of each letter.
        var startIndex = 0
        let letterDrawings = strokeCount.enumerated().map { (strokeIndex, strokeCount) -> PKDrawing in
            var letter = PKDrawing(strokes: adjustedStrokes[startIndex..<(startIndex + strokeCount)])
            
            // Normalize baselines based on drawing layout.
            let baseline = CGFloat(strokeIndex / 7 * 81) + 140
            letter.transform(using: CGAffineTransform(translationX: -letter.bounds.minX, y: -baseline))
            
            startIndex += strokeCount
            return letter
        }
        return letterDrawings
    }
}
