import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct LauncherView: View {
    @EnvironmentObject var vm: LauncherViewModel
    @EnvironmentObject var manager: NotchWindowManager
    @State private var showAddPopover = false
    @State private var draggedAppID: String?
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    private let columns = Array(repeating: GridItem(.fixed(58), spacing: 5), count: 8)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(vm.apps.prefix(LauncherViewModel.maxPinnedApps))) { app in
                        AppIconTile(item: app,
                                    isDragging: draggedAppID == app.id,
                                    onLaunch: { vm.launch(app) },
                                    onRemove: { remove(app) },
                                    onDragStarted: {
                                        startDrag(app)
                                    },
                                    onDropEntered: {
                                        reorderDraggedApp(over: app)
                                    },
                                    onDropEnded: {
                                        resetDrag()
                                    })
                    }

                    AddTile(isEnabled: vm.apps.count < LauncherViewModel.maxPinnedApps) {
                        showAddPopover.toggle()
                    }
                    .environment(\.locale, localeForLanguage(languageCode))
                    .onDrop(
                        of: [.text],
                        delegate: LauncherEndDropDelegate(
                            draggedAppID: $draggedAppID,
                            vm: vm,
                            onDropEnded: resetDrag
                        )
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .animation(.spring(response: 0.24, dampingFraction: 0.82), value: vm.apps)

                if showAddPopover {
                    AddAppPopover(vm: vm, isOpen: $showAddPopover)
                        .frame(width: min(proxy.size.width, 500),
                               height: min(proxy.size.height, 156),
                               alignment: .top)
                        .padding(.top, 2)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                            removal: .opacity
                        ))
                        .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { vm.reloadFromStorageIfChanged() }
        .onDisappear {
            showAddPopover = false
            resetDrag()
        }
    }

    private func remove(_ app: AppItem) {
        if let idx = vm.apps.firstIndex(where: { $0.id == app.id }) {
            vm.remove(at: IndexSet(integer: idx))
        }
    }

    private func localeForLanguage(_ code: String) -> Locale {
        Locale(identifier: code)
    }

    private func startDrag(_ app: AppItem) {
        draggedAppID = app.id
        showAddPopover = false
    }

    private func reorderDraggedApp(over app: AppItem) {
        guard let draggedAppID else { return }
        vm.move(draggedID: draggedAppID, over: app.id)
    }

    private func resetDrag() {
        draggedAppID = nil
    }
}

// MARK: - App Icon Tile

private struct AppIconTile: View {
    let item: AppItem
    let isDragging: Bool
    let onLaunch: () -> Void
    let onRemove: () -> Void
    let onDragStarted: () -> Void
    let onDropEntered: () -> Void
    let onDropEnded: () -> Void
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            iconSurface
                .onTapGesture(perform: onLaunch)
                .onDrag {
                    onDragStarted()
                    return NSItemProvider(object: item.id as NSString)
                } preview: {
                    Image(nsImage: item.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                }
                .onDrop(
                    of: [.text],
                    delegate: LauncherAppDropDelegate(
                        onDropEntered: onDropEntered,
                        onDropEnded: onDropEnded
                    )
                )

            if isHovered && !isDragging {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white, .red.opacity(0.9))
                        .background(Circle().fill(.black).padding(2))
                }
                .buttonStyle(.plain)
                .offset(x: -4, y: -4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 56, height: 56)
        .scaleEffect(isDragging ? 0.92 : 1)
        .opacity(isDragging ? 0.45 : 1)
        .onHover { isHovered = $0 }
        .help("Click to open. Drag to reorder.")
        .accessibilityLabel(item.name)
    }

    private var iconSurface: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(isHovered && !isDragging ? 0.08 : 0.02))
            .frame(width: 56, height: 56)
            .overlay {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .scaleEffect(isHovered && !isDragging ? 1.08 : 1.0)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                    .animation(.spring(response: 0.2), value: isHovered)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct LauncherAppDropDelegate: DropDelegate {
    let onDropEntered: () -> Void
    let onDropEnded: () -> Void

    func dropEntered(info: DropInfo) {
        onDropEntered()
    }

    func performDrop(info: DropInfo) -> Bool {
        onDropEnded()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct LauncherEndDropDelegate: DropDelegate {
    @Binding var draggedAppID: String?
    @ObservedObject var vm: LauncherViewModel
    let onDropEnded: () -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedAppID else { return }
        vm.moveToEnd(draggedID: draggedAppID)
    }

    func performDrop(info: DropInfo) -> Bool {
        onDropEnded()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Add Tile

private struct AddTile: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var isHovered = false
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(isHovered && isEnabled ? 0.08 : 0.015))
                    .frame(width: 56, height: 56)

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(isEnabled ? (isHovered ? 0.45 : 0.18) : 0.08),
                        style: StrokeStyle(lineWidth: 1.2, dash: [3])
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(isEnabled ? (isHovered ? 0.9 : 0.5) : 0.18))
            }
            .scaleEffect(isHovered && isEnabled ? 1.05 : 1.0)
            .animation(.spring(response: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .frame(width: 56, height: 56)
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onHover { isHovered = $0 }
        .help(isEnabled ? L10n.tr(.addAppHelp, languageCode) : L10n.tr(.launcherFullHelp, languageCode))
    }
}

// MARK: - Add App Popover

private struct AddAppPopover: View {
    @ObservedObject var vm: LauncherViewModel
    @Binding var isOpen: Bool
    @State private var query = ""
    @State private var allResults: [AppItem] = []
    @State private var results: [AppItem] = []
    @State private var isLoading = true
    @FocusState private var isSearchFieldFocused: Bool
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    // Compact grid — icon-first tiles, ~7 per row at panel width.
    private let gridColumns = Array(repeating: GridItem(.fixed(58), spacing: 9, alignment: .top), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: title + search + close
            HStack(spacing: 8) {
                Text(L10n.tr(.addApp, languageCode))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 11))
                    TextField("", text: $query, prompt: searchPrompt)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 12))
                        .focused($isSearchFieldFocused)
                        .onChange(of: query) { q in
                            results = filteredInstalledApps(matching: q)
                        }
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )

                Text("\(filteredResults.count)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .monospacedDigit()

                Button { isOpen = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .frame(height: 30)

            // Grid of installed apps
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView().controlSize(.small).tint(.white.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredResults.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.35))
                        Text(query.isEmpty ? L10n.tr(.noAppsFound, languageCode) : "\(L10n.tr(.noMatches, languageCode)): \(query)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: true) {
                        LazyVGrid(columns: gridColumns, spacing: 6) {
                            ForEach(filteredResults) { app in
                                AppSearchTile(app: app) {
                                    vm.add(app)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.08, blue: 0.19).opacity(0.98),
                            Color(red: 0.04, green: 0.035, blue: 0.06).opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.68, green: 0.5, blue: 1.0).opacity(0.26), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.42, green: 0.23, blue: 0.85).opacity(0.28), radius: 18, y: 10)
        .onAppear {
            // Populate off the main thread so the popover animates in smoothly.
            isLoading = true
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let apps = vm.installedApps(matching: "")
                DispatchQueue.main.async {
                    allResults = apps
                    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    results = trimmedQuery.isEmpty
                        ? apps
                        : apps.filter { $0.name.localizedStandardContains(trimmedQuery) }
                    isLoading = false
                    isSearchFieldFocused = true
                }
            }
        }
    }

    private func filteredInstalledApps(matching query: String) -> [AppItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return allResults }

        return allResults.filter { $0.name.localizedStandardContains(trimmedQuery) }
    }

    private var filteredResults: [AppItem] {
        results.filter { candidate in
            !vm.apps.contains(where: { $0.id == candidate.id })
        }
    }

    private var searchPrompt: Text {
        Text(L10n.tr(.searchInstalledApps, languageCode)).foregroundColor(Color.white.opacity(0.4))
    }
}

private struct AppSearchTile: View {
    let app: AppItem
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(isHovered ? 0.12 : 0.04))
                        .frame(width: 52, height: 52)

                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .scaleEffect(isHovered ? 1.06 : 1.0)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                    if isHovered {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white, Color.accentColor)
                            .offset(x: 15, y: -15)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.2), value: isHovered)

                Text(app.name)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(isHovered ? 0.95 : 0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 56)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.name)
        .onHover { isHovered = $0 }
    }
}
