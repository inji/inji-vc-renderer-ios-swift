import UIKit
import WebKit
import PDFKit

public class SvgToPdfConvertor {

    
    public static func svgListToPdfBase64(svgList: [String], pageSize: CGSize = CGSize(width: 595, height: 842)) async -> String? {
         let pdfDocument = PDFDocument()
         
         for (index, svgString) in svgList.enumerated() {
             if let image = await renderSvgToImage(svgString: svgString, size: pageSize),
                let pdfPage = PDFPage(image: image) {
                 pdfDocument.insert(pdfPage, at: index)
             } else {
                 print("⚠️ Failed to render SVG at index \(index)")
             }
         }
         
         guard let data = pdfDocument.dataRepresentation() else {
             print("❌ Failed to generate PDF data")
             return nil
         }
         
         return data.base64EncodedString()
     }
     
    private static func renderSvgToImage(svgString: String, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let webView = WKWebView(frame: CGRect(origin: .zero, size: size))
                webView.isOpaque = false
                webView.backgroundColor = .clear
                webView.scrollView.isScrollEnabled = false

                class SnapshotDelegate: NSObject, WKNavigationDelegate {
                    let onFinish: () -> Void
                    init(onFinish: @escaping () -> Void) {
                        self.onFinish = onFinish
                    }
                    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                        // Wait a bit to let SVG render fully
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.onFinish()
                        }
                    }
                }

                let delegate = SnapshotDelegate {
                    let config = WKSnapshotConfiguration()
                    config.rect = CGRect(origin: .zero, size: size)
                    config.afterScreenUpdates = true

                    webView.takeSnapshot(with: config) { image, error in
                        continuation.resume(returning: image)
                    }
                }

                // Retain delegate
                objc_setAssociatedObject(webView, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                webView.navigationDelegate = delegate

                let htmlWrapper = """
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { margin: 0; padding: 0; }
                        svg { width: 100vw; height: 100vh; }
                    </style>
                </head>
                <body>
                    \(svgString)
                </body>
                </html>
                """

                webView.loadHTMLString(htmlWrapper, baseURL: nil)
            }
        }
    }



}
