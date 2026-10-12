func demo() {
    _ = L10n.t("custom_key")
    _ = tr("tr_key")
    _ = "still_plain"
}

enum L10n {
    static func t(_ key: String) -> String { key }
}

func tr(_ key: String) -> String { key }
