import Foundation

enum JsonPointerError: Error {
    case invalidPointer
    case notFound
    case typeMismatch
}

final class JsonPointerResolver {
    private static let placeholderRegex = try! NSRegularExpression(
        pattern: #"\{\{(/[^}]*)\}\}|\{\{\}\}"#
    )
    public static let className = String(describing: JsonPointerResolver.self)


    /// Replaces placeholders in an SVG template using a Verifiable Credential JSON.
    /// Supports optional whitelist of allowed placeholders.
    static func replacePlaceholders(svgTemplate: String,
                                    vcJson: Any,
                                    renderProperties: [String]? = nil,
                                    traceabilityId: String) throws -> String {
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
                value = vcJson
            } else {
                do {
                        value = try resolvePointer(root: vcJson, pointer: pointerPath)
                    } catch JsonPointerError.notFound {
                        print("ERROR [\(VcRendererErrorCodes.missingJsonPath)] - Missing: \(pointerPath) | Class: \(className) | TraceabilityId: \(traceabilityId)")
                        value = nil
                    } catch let error {
                        print("ERROR while resolving pointer \(pointerPath): \(error) | Class: \(className) | TraceabilityId: \(traceabilityId)")
                        value = nil
                    }
            }

            let replacement: String
            switch value {
            case nil:
                replacement = "-"
            case let v as String:
                replacement = v
            case let v as NSNumber:
                replacement = v.stringValue
            case let v as [Any]:
                replacement = jsonString(from: v) ?? "\(v)"
            case let v as [String: Any]:
                replacement = jsonString(from: v) ?? "\(v)"
            default:
                replacement = "-"
            }

            result.replaceSubrange(Range(match.range, in: result)!, with: replacement)
        }

        return result
    }

    /// Strict RFC 6901 JSON Pointer resolution
    static func resolvePointer(root: Any, pointer: String) throws -> Any {
        if pointer.isEmpty { return root }
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
}
