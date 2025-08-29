import Foundation

class SvgMultilineFormatter {
    
    static func chunkArrayFields(_ array: [Any], svgWidth: Int, avgCharWidth: Int = 8) -> String {
        let combined = array.map { "\($0)" }.joined(separator: ", ")
        return wrapText(combined, svgWidth: svgWidth, avgCharWidth: avgCharWidth)
    }
    
    static func chunkAddressFields(_ address: String, svgWidth: Int, avgCharWidth: Int = 8) -> String {
        return wrapText(address, svgWidth: svgWidth, avgCharWidth: avgCharWidth)
    }
    
    private static func wrapText(_ text: String, svgWidth: Int, avgCharWidth: Int) -> String {
        let charsPerLine = max(svgWidth / avgCharWidth, 1)
        let words = text.split(separator: " ")
        
        var lines: [String] = []
        var currentLine = ""
        
        for word in words {
            if currentLine.count + word.count + 1 > charsPerLine {
                lines.append(currentLine.trimmingCharacters(in: .whitespaces))
                currentLine = String(word)
            } else {
                if !currentLine.isEmpty {
                    currentLine += " "
                }
                currentLine += word
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.map { line in
            "<tspan x=\"0\" dy=\"1.2em\">\(line)</tspan>"
        }.joined()
    }
}
