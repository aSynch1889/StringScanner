import SwiftUI
import StringScannerCore

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            ResultsView(viewModel: viewModel)
        }
        .alert("Notice", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("String Scanner")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a project folder to scan for strings")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            VStack(spacing: 15) {
                Button(action: viewModel.selectFolder) {
                    Label("Select Folder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning)
                
                Text(viewModel.selectedPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal)
                
                Button(action: viewModel.startScan) {
                    if viewModel.isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    } else {
                        Text("Start Scan")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedPath.isEmpty || viewModel.isScanning)
            }
            .padding()
            
            if viewModel.isScanning {
                ProgressView(value: viewModel.progress) {
                    Text("Scanning...")
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(minWidth: 250)
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @State private var searchText = ""
    
    private var filteredResults: [StringLocation] {
        guard !searchText.isEmpty else { return viewModel.results }
        return viewModel.results.filter { result in
            result.content.localizedCaseInsensitiveContains(searchText)
                || result.file.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            if viewModel.results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Results")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Select a folder and start scanning to find strings")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    HStack {
                        Text("\(filteredResults.count) of \(viewModel.results.count) strings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: viewModel.exportToJSON) {
                            Label("Export JSON", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToCSV) {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                    List(filteredResults, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.content)
                                .font(.body)
                            
                            HStack {
                                Text(result.file)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Line \(result.line)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if result.isLocalized {
                                    Text("Localized")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .searchable(text: $searchText, prompt: "Filter by content or file path")
                }
            }
        }
        .frame(minWidth: 500)
    }
}

#Preview {
    ContentView()
}
