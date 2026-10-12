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
    @State private var updateMessage: String?
    @State private var updateURL: URL?
    @State private var isCheckingUpdate = false

    private var hasFolder: Bool { !viewModel.selectedPath.isEmpty }
    private var canScan: Bool { hasFolder && !viewModel.isScanning }

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
                        .tint(canScan || viewModel.isScanning ? .white : AppTheme.tertiaryText)
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
            .foregroundStyle(canScan || viewModel.isScanning ? .white : AppTheme.tertiaryText)
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
        .opacity(hasFolder || viewModel.isScanning ? 1 : 0.7)
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
                sectionLabel(L10n.t(.appearance))
                Picker("", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.title(language: settings.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(L10n.t(.language))
                Picker("", selection: Binding(
                    get: { settings.language },
                    set: { settings.language = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
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

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(L10n.t(.updates))
                Text(L10n.format(.versionLabel, AppVersion.current))
                    .font(AppTheme.monoCaption)
                    .foregroundStyle(AppTheme.secondaryText)
                Button {
                    Task { await checkForUpdates() }
                } label: {
                    HStack {
                        if isCheckingUpdate {
                            ProgressView().controlSize(.small)
                        }
                        Text(L10n.t(.checkForUpdates))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isCheckingUpdate)

                if let updateMessage {
                    Text(updateMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let updateURL {
                    Link(L10n.t(.openReleasePage), destination: updateURL)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
        }
    }

    @MainActor
    private func checkForUpdates() async {
        isCheckingUpdate = true
        updateMessage = nil
        updateURL = nil
        defer { isCheckingUpdate = false }

        switch await UpdateChecker.check() {
        case .upToDate(let current):
            updateMessage = L10n.format(.upToDate, current)
        case .available(let release):
            updateMessage = L10n.format(.updateAvailable, release.tagName)
            updateURL = release.htmlURL
        case .failed(let message):
            updateMessage = message
            updateURL = AppVersion.releasesPage
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(1.0)
            .foregroundStyle(AppTheme.tertiaryText)
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
                .frame(minWidth: 220, idealWidth: 260)
                .labelsHidden()
                .disabled(viewModel.results.isEmpty)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: viewModel.exportToJSON) {
                    Label(L10n.t(.exportJSON), systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.results.isEmpty)
                .help(L10n.t(.exportJSON))

                Button(action: viewModel.exportToCSV) {
                    Label(L10n.t(.exportCSV), systemImage: "tablecells")
                }
                .disabled(viewModel.results.isEmpty)
                .help(L10n.t(.exportCSV))
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
                List(filteredResults, id: \.self) { result in
                    resultRow(result)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(AppTheme.elevatedBackground.opacity(0.72))
                        .listRowSeparatorTint(AppTheme.separator)
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

                if result.isLocalized {
                    Text(L10n.t(.localizedBadge))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(AppTheme.tealDeep)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.teal.opacity(0.16))
                        )
                }

                if result.catalogStatus == .missing {
                    Text(L10n.t(.catalogMissingBadge))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(Color(red: 0.72, green: 0.32, blue: 0.18))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.86, green: 0.45, blue: 0.22).opacity(0.16))
                        )
                }
            }

            HStack(spacing: 8) {
                Text(displayPath(for: result.file))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("·")
                Text("L\(result.line)")
                Text("·")
                Text("C\(result.column)")
            }
            .font(AppTheme.monoCaption)
            .foregroundStyle(AppTheme.tertiaryText)
            .textSelection(.enabled)
        }
        .padding(.vertical, 2)
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
        .frame(width: 980, height: 640)
}
