import UIKit
import SVGKit
import Foundation

func svgListToPdfBase64(svgList: [String]) -> String? {
    let pdfData = NSMutableData()
    
    // Setup PDF renderer with large default size, will be adjusted per SVG
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    // Begin PDF context writing into NSMutableData
    UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
    
    for svgString in svgList {
        // Parse SVG string into SVGKImage
        guard let svgData = svgString.data(using: .utf8),
              let svgImage = SVGKImage(data: svgData) else {
            continue
        }
        
        let size = svgImage.size
        UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: size), nil)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            // Render SVG onto CGContext
            svgImage.render(in: context)
            context.restoreGState()
        }
    }
    
    UIGraphicsEndPDFContext()
    
    // Convert to Base64
    return pdfData.base64EncodedString(options: [])
}

