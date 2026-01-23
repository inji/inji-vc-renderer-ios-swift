import Foundation

enum JsonPointerError: Error {
    case invalidPointer
    case notFound
    case typeMismatch
}

final class JsonPointerResolver {
    private let traceabilityId: String

    private static let placeholderRegex = try! NSRegularExpression(
        pattern: #"\{\{(/[^}]*)\}\}|\{\{\}\}"#
    )
    public static let className = String(describing: JsonPointerResolver.self)
    private let qrCodeGenerator: QrCodeGeneratorProtocol = QrCodeGenerator() as QrCodeGeneratorProtocol

    
    init(traceabilityId: String) {
        self.traceabilityId = traceabilityId
    }



    private static func toReplaceMentString(_ value: Any?) -> String {
        switch value {
        case nil:
            return "-"
        case let v as String:
            return v
        case let v as NSNumber:
            return v.stringValue
        case let v as [Any]:
            return jsonString(from: v) ?? "\(v)"
        case let v as [String: Any]:
            return jsonString(from: v) ?? "\(v)"
        default:
            return "-"
        }
    }
    
    /// Replaces placeholders in an SVG template using a Verifiable Credential JSON.
    /// Supports optional whitelist of allowed placeholders.
    static func replacePlaceholders(svgTemplate: String,
                                    inputJson: Any,
                                    renderProperties: [String]? = nil,
                                    traceabilityId: String
    ) throws -> String {
        let nsRange = NSRange(svgTemplate.startIndex..<svgTemplate.endIndex,
                              in: svgTemplate)
        var result = svgTemplate
        let matches = placeholderRegex.matches(in: svgTemplate,
                                               range: nsRange).reversed()

        for match in matches {
            let range = match.range(at: 1)
            let pointerPath: String
            if let r = Range(range, in: svgTemplate) {
                pointerPath = String(svgTemplate[r])
            } else {
                pointerPath = ""
            }

            if let props = renderProperties, !props.contains(pointerPath) {
                result.replaceSubrange(Range(match.range, in: result)!, with: "-")
                continue
            }

            let value: Any?
            if pointerPath.isEmpty {
                value = inputJson
            } else {
                do {
                        value = try resolvePointer(root: inputJson, pointer: pointerPath)
                    } catch JsonPointerError.notFound {
                        print("ERROR [\(VcRendererErrorCodes.missingJsonPath)] - Missing: \(pointerPath) | Class: \(className) | TraceabilityId: \(traceabilityId)")
                        value = nil
                    } catch let error {
                        print("ERROR while resolving pointer \(pointerPath): \(error) | Class: \(className) | TraceabilityId: \(traceabilityId)")
                        value = nil
                    }
            }

            let replacement: String = toReplaceMentString(value)

            result.replaceSubrange(Range(match.range, in: result)!, with: replacement)
        }

        return result
    }

    /// Strict RFC 6901 JSON Pointer resolution
    static func resolvePointer(root: Any, pointer: String) throws -> Any {
        if pointer.isEmpty {
            return root
        }
        guard pointer.first == "/" else { throw JsonPointerError.invalidPointer }

        let tokens = pointer.dropFirst().split(separator: "/").map {
            $0.replacingOccurrences(of: "~1", with: "/")
              .replacingOccurrences(of: "~0", with: "~")
        }

        var current: Any = root
        for token in tokens {
            if let dict = current as? [String: Any] {
                guard let next = dict[token] else { throw JsonPointerError.notFound }
                current = next
            } else if let arr = current as? [Any],
                      let idx = Int(token), idx >= 0, idx < arr.count {
                current = arr[idx]
            } else {
                throw JsonPointerError.typeMismatch
            }
        }
        return current
    }

    private static func jsonString(from value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value) else { return nil }
        if let data = try? JSONSerialization.data(withJSONObject: value,
                                                  options: []),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
    
    func replaceSvgPlaceholders(
        svgTemplate: String,
        vcJson: [String: Any],
        renderMethodElement: [String: Any],
        vcJsonString: String,
        qrCodeData: String?
    ) throws -> String {
        let svgWithQrCodeReplaced = replaceQrCodePlaceholder(svgTemplate: svgTemplate, vcJsonString: vcJsonString, qrCodeData: qrCodeData)
        return try replaceVcPlaceholders(svgTemplate: svgWithQrCodeReplaced, vcJson: vcJson, element: renderMethodElement)
    }
    
    private func replaceVcPlaceholders(svgTemplate: String, vcJson: [String: Any], element: [String: Any])throws -> String {
        var renderProperties: [String]? = nil
                if let template = element[Constants.template] as? [String: Any],
                   let renderProperty = template[Constants.renderProperty] as? [String] {
                    renderProperties = renderProperty
                }
        return  try JsonPointerResolver.replacePlaceholders(
             svgTemplate: svgTemplate,
             inputJson: vcJson,
            renderProperties: renderProperties,
            traceabilityId: traceabilityId
        )

    }
    
    private func replaceQrCodePlaceholder(
        svgTemplate: String,
            vcJsonString: String,
        qrCodeData: String?
        ) -> String {
            guard svgTemplate.contains(Constants.qrCodePlaceholder) else {
                return svgTemplate
            }
        

            let qrBase64: String?
            do {
                if let qrData = qrCodeData, !qrData.isEmpty {
                        qrBase64 = try qrCodeGenerator.generateFromQrData(
                            qrData: qrData,
                            traceabilityId: traceabilityId
                        )
                    } else {
                    qrBase64 = try qrCodeGenerator.generateFromVcJson(
                        vcJson: vcJsonString,
                        traceabilityId: traceabilityId
                    )
                }
            } catch {
                qrBase64 = nil
            }

            let (finalQrBase64, imageId): (String, String) = {
                if let qr = qrBase64, !qr.isEmpty {
                    return (qr, Constants.qrCodeImageId)
                } else {
                    return (Constants.fallbackQrCode, Constants.qrCodeFallbackImageId)
                }
            }()

            let qrImageTag = "\(Constants.qrImagePrefix),\(finalQrBase64)"

            return svgTemplate
                .replacingOccurrences(of: Constants.qrCodePlaceholder, with: qrImageTag)
                .replacingOccurrences(of: Constants.qrCodeImageId, with: imageId)
        }
}
