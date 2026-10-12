import Foundation
import SwiftSyntax

public struct LocalizationFunctionSpec: Hashable, Sendable, Codable {
    /// Simple call name (`tr`) or member path (`L10n.t`).
    public let pattern: String

    public init(pattern: String) {
        self.pattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static let builtInDefaults: [LocalizationFunctionSpec] = [
        LocalizationFunctionSpec(pattern: "NSLocalizedString"),
        LocalizationFunctionSpec(pattern: "Text"),
        LocalizationFunctionSpec(pattern: "LocalizedStringKey"),
        LocalizationFunctionSpec(pattern: "String.localized")
    ]

    var isStringLocalizedAPI: Bool {
        pattern == "String.localized" || pattern == "String(localized:)"
    }

    func matches(functionCall: FunctionCallExprSyntax) -> Bool {
        if isStringLocalizedAPI {
            guard let ref = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
                  ref.baseName.text == "String" else {
                return false
            }
            return functionCall.arguments.contains { $0.label?.text == "localized" }
        }

        if pattern.contains(".") {
            let parts = pattern.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 2,
                  let member = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                  member.declName.baseName.text == parts[1] else {
                return false
            }
            if let base = member.base?.as(DeclReferenceExprSyntax.self) {
                return base.baseName.text == parts[0]
            }
            return false
        }

        if let ref = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text == pattern
        }

        if let member = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
           member.base == nil {
            // `.Text` style unlikely; keep simple name match on last component
            return member.declName.baseName.text == pattern
        }

        return false
    }
}

public enum LocalizationFunctionMatcher {
    public static func parseList(_ raw: String) -> [LocalizationFunctionSpec] {
        raw
            .split(separator: ",")
            .map { LocalizationFunctionSpec(pattern: String($0)) }
            .filter { !$0.pattern.isEmpty }
    }

    public static func merged(custom: [LocalizationFunctionSpec]) -> [LocalizationFunctionSpec] {
        var seen = Set<String>()
        var result: [LocalizationFunctionSpec] = []
        for spec in LocalizationFunctionSpec.builtInDefaults + custom {
            let key = spec.pattern
            if seen.insert(key).inserted {
                result.append(spec)
            }
        }
        return result
    }
}
