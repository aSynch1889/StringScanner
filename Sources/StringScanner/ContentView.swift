import SwiftUI
import StringScannerCore

private enum ResultFilter: String, CaseIterable, Identifiable {
    case all
    case localized
    case plain

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all: return L10n.string(.filterAll, language: language)
        case .localized: return L10n.string(.filterLocalized, language: language)
        case .plain: return L10n.string(.filterPlain, language: language)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 360)
        } detail: {
            ResultsView(viewModel: viewModel)
        }
        .tint(AppTheme.teal)
        .preferredColorScheme(settings.appearance.colorScheme)
        .id(settings.language.rawValue)
        .alert(L10n.t(.notice), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.errorMessage = nil }
            }
        )) {
            Button(L10n.t(.ok), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var updateStatus: UpdateStatus

    private var hasFolder: Bool { !viewModel.selectedPath.isEmpty }
    private var canScan: Bool { hasFolder && !viewModel.isScanning }
    private var canExport: Bool { !viewModel.results.isEmpty }

    private var localizedCount: Int {
        viewModel.results.filter(\.isLocalized).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 14) {
                sectionLabel(L10n.t(.target))

                folderButton

                if hasFolder {
                    Text(shortPath(viewModel.selectedPath))
                        .font(AppTheme.monoCaption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                        .textSelection(.enabled)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                scanButton

                if viewModel.isScanning {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: viewModel.progress)
                            .tint(AppTheme.teal)
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(AppTheme.monoCaption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 22)
            .animation(.easeInOut(duration: 0.2), value: hasFolder)

            Spacer(minLength: 20)

            if !viewModel.results.isEmpty {
                statsPanel
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
            } else {
                Text(L10n.t(.pickHint))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.tertiaryText)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
            }

            preferencesPanel
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
        }
        .background(AppTheme.sidebarBackground.ignoresSafeArea())
        .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 360)
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppTheme.teal)
                    .frame(width: 8, height: 28)
                Text("StringScanner")
                    .font(AppTheme.brandFont)
                    .foregroundStyle(AppTheme.primaryText)
            }
            Text(L10n.t(.brandSubtitle))
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var folderButton: some View {
        Button(action: viewModel.selectFolder) {
            HStack(spacing: 10) {
                Image(systemName: hasFolder ? "folder" : "folder.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                Text(hasFolder ? L10n.t(.changeFolder) : L10n.t(.chooseFolder))
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(hasFolder ? AppTheme.primaryText : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hasFolder ? AppTheme.panelFill : AppTheme.teal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(hasFolder ? AppTheme.panelStroke : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isScanning)
    }

    private var scanButton: some View {
        Button {
            viewModel.startScan(localizationFunctions: settings.localizationFunctions)
        } label: {
            HStack {
                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .tint(canScan || viewModel.isScanning ? .white : AppTheme.secondaryText)
                } else {
                    Image(systemName: "waveform.and.magnifyingglass")
                }
                Text(viewModel.isScanning ? L10n.t(.scanning) : L10n.t(.startScan))
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
                if canScan {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(canScan || viewModel.isScanning ? .white : AppTheme.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(scanButtonFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(canScan ? Color.clear : AppTheme.panelStroke, lineWidth: 1)
                    )
            )
            .shadow(color: canScan ? AppTheme.teal.opacity(0.28) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!canScan && !viewModel.isScanning)
        .opacity(hasFolder || viewModel.isScanning ? 1 : 0.88)
    }

    private var scanButtonFill: Color {
        if viewModel.isScanning { return AppTheme.teal.opacity(0.85) }
        if canScan { return AppTheme.teal }
        return AppTheme.panelFill
    }

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.t(.session))
            HStack(spacing: 10) {
                statChip(title: L10n.t(.found), value: "\(viewModel.results.count)")
                statChip(title: L10n.t(.localized), value: "\(localizedCount)")
            }
        }
    }

    private var preferencesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().overlay(AppTheme.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(L10n.t(.exportMenu))
                Menu {
                    Button(L10n.t(.exportXCStrings), action: viewModel.exportToXCStrings)
                    Button(L10n.t(.exportStrings), action: viewModel.exportToStrings)
                    Divider()
                    Button(L10n.t(.exportJSON), action: viewModel.exportToJSON)
                    Button(L10n.t(.exportCSV), action: viewModel.exportToCSV)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.t(.exportMenu))
                            .font(.system(size: 13, weight: .semibold))
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                    .foregroundStyle(canExport ? AppTheme.primaryText : AppTheme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.panelFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(AppTheme.panelStroke, lineWidth: 1)
                            )
                    )
                }
                .disabled(!canExport)
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(L10n.t(.localizeFunctions))
                TextField("L10n.t, tr", text: Binding(
                    get: { settings.localizationFunctionsCSV },
                    set: { settings.localizationFunctionsCSV = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(AppTheme.monoCaption)
                Text(L10n.t(.localizeFunctionsHint))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            VStack(alignment: .leading, spacing: 6) {
                sectionLabel(L10n.t(.updates))
                HStack(spacing: 8) {
                    Text(L10n.format(.versionLabel, AppVersion.current))
                        .font(AppTheme.monoCaption)
                        .foregroundStyle(AppTheme.secondaryText)

                    if updateStatus.hasUpdate {
                        Link(destination: updateStatus.releaseURL) {
                            Text(L10n.t(.updateBadge))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.3)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.teal)
                                )
                        }
                        .help(L10n.t(.updateAvailableHint))
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(1.0)
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.tertiaryText)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.panelStroke, lineWidth: 1)
                )
        )
    }

    private func shortPath(_ path: String) -> String {
        if path.hasPrefix(NSHomeDirectory()) {
            return "~" + path.dropFirst(NSHomeDirectory().count)
        }
        return path
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @EnvironmentObject private var settings: AppSettings
    @State private var searchText = ""
    @State private var filter: ResultFilter = .all

    private var filteredResults: [StringLocation] {
        viewModel.results.filter { result in
            switch filter {
            case .all: break
            case .localized: if !result.isLocalized { return false }
            case .plain: if result.isLocalized { return false }
            }
            guard !searchText.isEmpty else { return true }
            return result.content.localizedCaseInsensitiveContains(searchText)
                || result.file.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedResults: [(file: String, items: [StringLocation])] {
        Dictionary(grouping: filteredResults, by: \.file)
            .map { (file: $0.key, items: $0.value) }
            .sorted { $0.file < $1.file }
    }

    var body: some View {
        ZStack {
            MeshBackdrop()

            Group {
                if viewModel.results.isEmpty && !viewModel.isScanning {
                    emptyState
                } else if viewModel.isScanning && viewModel.results.isEmpty {
                    scanningState
                } else {
                    resultsContent
                }
            }
        }
        .frame(minWidth: 560)
        .navigationTitle("")
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: L10n.t(.filterPlaceholder)
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $filter) {
                    ForEach(ResultFilter.allCases) { item in
                        Text(item.title(language: settings.language)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200, idealWidth: 240)
                .labelsHidden()
                .disabled(viewModel.results.isEmpty)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(AppAppearance.allCases) { mode in
                        Button {
                            settings.appearance = mode
                        } label: {
                            if settings.appearance == mode {
                                Label(
                                    mode.title(language: settings.language),
                                    systemImage: "checkmark"
                                )
                            } else {
                                Text(mode.title(language: settings.language))
                            }
                        }
                    }
                } label: {
                    Label(
                        settings.appearance.title(language: settings.language),
                        systemImage: "circle.lefthalf.filled"
                    )
                }
                .help(L10n.t(.appearance))

                Menu {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            settings.language = language
                        } label: {
                            if settings.language == language {
                                Label(language.displayName, systemImage: "checkmark")
                            } else {
                                Text(language.displayName)
                            }
                        }
                    }
                } label: {
                    Label(settings.language.displayName, systemImage: "globe")
                }
                .help(L10n.t(.language))
            }
        }
        .toolbarBackground(AppTheme.windowBackground, for: .windowToolbar)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.teal.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(AppTheme.tealDeep)
            }
            Text(L10n.t(.noScanYet))
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(AppTheme.primaryText)
            Text(L10n.t(.emptyHint))
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scanningState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.teal)
            Text(L10n.t(.scanningProject))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text("\(Int(viewModel.progress * 100))%")
                .font(AppTheme.monoCaption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsContent: some View {
        Group {
            if filteredResults.isEmpty {
                VStack(spacing: 8) {
                    Text(L10n.t(.noMatches))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(L10n.t(.noMatchesHint))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedResults, id: \.file) { group in
                        Section {
                            ForEach(group.items, id: \.self) { result in
                                resultRow(result)
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                    .listRowBackground(AppTheme.elevatedBackground.opacity(0.72))
                                    .listRowSeparatorTint(AppTheme.separator)
                            }
                        } header: {
                            HStack {
                                Text(displayPath(for: group.file))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text("\(group.items.count)")
                                    .font(AppTheme.monoCaption)
                                    .foregroundStyle(AppTheme.tertiaryText)
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func resultRow(_ result: StringLocation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(result.content.isEmpty ? "\"\"" : result.content)
                    .font(AppTheme.mono)
                    .foregroundStyle(AppTheme.primaryText)
                    .textSelection(.enabled)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if result.isInterpolated {
                    badge(L10n.t(.interpolatedBadge), tint: AppTheme.secondaryText)
                }
                if result.isLocalized {
                    badge(L10n.t(.localizedBadge), tint: AppTheme.tealDeep, fill: AppTheme.teal.opacity(0.16))
                }
                if result.catalogStatus == .missing {
                    badge(
                        L10n.t(.catalogMissingBadge),
                        tint: Color(red: 0.72, green: 0.32, blue: 0.18),
                        fill: Color(red: 0.86, green: 0.45, blue: 0.22).opacity(0.16)
                    )
                }
            }

            HStack(spacing: 8) {
                Text("L\(result.line)")
                Text("·")
                Text("C\(result.column)")
                if result.origin != .sourceCode {
                    Text("·")
                    Text(result.origin.rawValue)
                }
                Spacer(minLength: 8)
                Button {
                    copyContent(result.content)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help(L10n.t(.copyKey))

                Button {
                    openInXcode(result)
                } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .buttonStyle(.borderless)
                .help(L10n.t(.openInXcode))
            }
            .font(AppTheme.monoCaption)
            .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(L10n.t(.copyKey)) { copyContent(result.content) }
            Button(L10n.t(.openInXcode)) { openInXcode(result) }
            Button(L10n.t(.revealInFinder)) { revealInFinder(result.file) }
        }
        .onTapGesture(count: 2) {
            openInXcode(result)
        }
    }

    private func badge(_ text: String, tint: Color, fill: Color = Color.clear) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(fill == .clear ? tint.opacity(0.12) : fill)
            )
    }

    private func copyContent(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func openInXcode(_ result: StringLocation) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xed")
        process.arguments = ["--line", "\(result.line)", result.file]
        do {
            try process.run()
        } catch {
            NSWorkspace.shared.open(URL(fileURLWithPath: result.file))
        }
    }

    private func revealInFinder(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    private func displayPath(for file: String) -> String {
        let root = viewModel.selectedPath
        if !root.isEmpty, file.hasPrefix(root) {
            let trimmed = String(file.dropFirst(root.count))
            return trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        }
        if file.hasPrefix(NSHomeDirectory()) {
            return "~" + file.dropFirst(NSHomeDirectory().count)
        }
        return file
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(UpdateStatus())
        .frame(width: 980, height: 640)
}
