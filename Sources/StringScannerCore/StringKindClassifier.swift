import Foundation
import SwiftSyntax

public enum StringKind: String, Codable, Sendable, Hashable, CaseIterable {
    case copy
    case url
    case log
    case sfSymbol
    case format
    case technical

    public static let defaultIncluded: Set<StringKind> = [.copy, .format]

    public static func parseList(_ raw: String) -> Set<StringKind> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == "all" {
            return Set(StringKind.allCases)
        }
        let kinds = trimmed
            .split(separator: ",")
            .compactMap { StringKind(rawValue: String($0).trimmingCharacters(in: .whitespaces)) }
        return Set(kinds)
    }
}

public struct StringClassificationContext: Sendable {
    public var isLogCall: Bool
    public var isSystemImage: Bool

    public init(isLogCall: Bool = false, isSystemImage: Bool = false) {
        self.isLogCall = isLogCall
        self.isSystemImage = isSystemImage
    }
}

enum StringKindClassifier {
    private static let urlPrefixes = ["http://", "https://", "ftp://", "file://"]
    private static let logCallNames: Set<String> = [
        "print", "debugPrint", "NSLog", "os_log", "Logger", "log"
    ]

    static func classify(content: String, context: StringClassificationContext) -> StringKind {
        if context.isLogCall { return .log }
        if context.isSystemImage { return .sfSymbol }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .technical }

        if urlPrefixes.contains(where: { trimmed.lowercased().hasPrefix($0) }) {
            return .url
        }
        if trimmed.contains("://") || trimmed.hasPrefix("www.") {
            return .url
        }

        if looksLikeSFSymbol(trimmed) {
            return .sfSymbol
        }

        if looksLikeFormat(trimmed) {
            return .format
        }

        if looksTechnical(trimmed) {
            return .technical
        }

        return .copy
    }

    static func context(for node: StringLiteralExprSyntax) -> StringClassificationContext {
        var isLog = false
        var isSystemImage = false
        var current: Syntax? = Syntax(node).parent

        while let syntax = current {
            if let call = syntax.as(FunctionCallExprSyntax.self) {
                let name = callName(of: call)
                if logCallNames.contains(name) {
                    isLog = true
                }
                if name == "Image" || name == "systemName" {
                    // Image(systemName: "x")
                    if call.arguments.contains(where: {
                        $0.label?.text == "systemName" &&
                            $0.expression.as(StringLiteralExprSyntax.self)?.position == node.position
                    }) {
                        isSystemImage = true
                    }
                }
                if let member = call.calledExpression.as(MemberAccessExprSyntax.self),
                   member.declName.baseName.text == "systemName" {
                    isSystemImage = true
                }
            }
            current = syntax.parent
        }

        return StringClassificationContext(isLogCall: isLog, isSystemImage: isSystemImage)
    }

    private static func callName(of call: FunctionCallExprSyntax) -> String {
        if let ref = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text
        }
        if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }
        return ""
    }

    private static func looksLikeSFSymbol(_ value: String) -> Bool {
        // e.g. "chevron.right", "square.and.arrow.up"
        guard value.count >= 3, value.count <= 64 else { return false }
        guard value.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "." || $0 == "_" }) else {
            return false
        }
        guard value.contains("."), !value.contains(" ") else { return false }
        let parts = value.split(separator: ".")
        // Avoid reverse-DNS / bundle identifiers
        if parts.count >= 3,
           ["com", "org", "net", "io", "app"].contains(String(parts[0])) {
            return false
        }
        return true
    }

    // Keep fixture parse friendly even without importing SwiftUI at top.


    private static func looksLikeFormat(_ value: String) -> Bool {
        value.contains("%@") ||
            value.contains("%d") ||
            value.contains("%ld") ||
            value.contains("%lld") ||
            value.contains("%f") ||
            value.contains("%i") ||
            value.range(of: #"%\d*\$?[@dfis]"#, options: .regularExpression) != nil
    }

    private static func looksTechnical(_ value: String) -> Bool {
        if value.count == 1 { return true }
        if value.hasPrefix("/") || value.hasPrefix("./") || value.hasPrefix("../") {
            return true
        }
        if value.contains("Bundle") || value.hasSuffix(".plist") || value.hasSuffix(".json") {
            return true
        }
        // UUID
        if value.range(
            of: #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#,
            options: .regularExpression
        ) != nil {
            return true
        }
        // reverse-dns bundle id style without spaces
        if value.contains(".") && !value.contains(" ") && value.allSatisfy({
            $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "_"
        }) && value.split(separator: ".").count >= 3 {
            return true
        }
        return false
    }
}
