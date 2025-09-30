import UIKit
import SVGKit

public class SvgToPdfConvertor {

    public static func svgListToPdfBase64(svgList: [String], pageSize: CGSize = CGSize(width: 595, height: 842)) -> String? {
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

            for svgString in svgList {
                guard let svgData = svgString.data(using: .utf8),
                      let svgImage = SVGKImage(data: svgData) else {
                    print("⚠️ Skipping invalid SVG")
                    continue
                }

                svgImage.scaleToFit(inside: pageSize)

                UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: pageSize), nil)

                guard let uiImage = svgImage.uiImage else {
                    print("⚠️ Skipping SVG, UIImage conversion failed")
                    continue
                }

                if let context = UIGraphicsGetCurrentContext() {
                    context.setFillColor(UIColor.white.cgColor)
                    context.fill(CGRect(origin: .zero, size: pageSize))

                    context.saveGState()
                    
                    let imageRect = CGRect(
                        x: (pageSize.width - uiImage.size.width) / 2,
                        y: (pageSize.height - uiImage.size.height) / 2,
                        width: uiImage.size.width,
                        height: uiImage.size.height
                    )
                    uiImage.draw(in: imageRect)
                    
                    context.restoreGState()
                }
            }

            UIGraphicsEndPDFContext()
            return pdfData.base64EncodedString(options: [])
        }

    

}
