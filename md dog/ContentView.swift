//
//  ContentView.swift
//  md dog
//
//  Created by 楊仁邦 on 2026/7/1.
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @State private var isShowingFileImporter = false
    @State private var selectedFileName = "未選擇檔案"
    @State private var markdownText = ""
    @State private var viewMode = ViewMode.preview
    @State private var textSize = 17.0
    @State private var tableColumnWidths: [Int: Double] = [:]
    @State private var tableDragStartWidths: [Int: Double] = [:]
    @State private var tableColorsDisabled: Set<Int> = []
    @State private var readerAvailableWidth: CGFloat = 780
    @State private var errorMessage: String?
    @State private var copiedCodeBlockID: Int?
    @State private var appearanceMode: AppearanceMode = .system
    @State private var fontFamily: FontFamily = .serif
    @State private var isShowingFontStepper = false
    @State private var isShowingSettings = false
    @State private var isShowingDonation = false
    @State private var unorderedListColor: ListColor = .mint
    @State private var orderedListColor: ListColor = .sky
    @State private var tableColor: ListColor = .lavender
    @State private var tableStripedRows: Bool = true
    @State private var stickyNotesEnabled: Bool = true
    @State private var stickyNoteColor: StickyNoteColor = .yellow
    @State private var isBottomBarVisible: Bool = true
    @State private var bottomBarHideTask: Task<Void, Never>?
    @State private var markdownBlocks: [MarkdownBlock] = []
    @State private var fileSummary: String = ""
    @State private var loadedImageURLs: Set<String> = []
    @State private var imageActionTarget: MarkdownImage?
    @State private var currentFileURL: URL?
    @State private var isEditing = false
    @State private var didJustSave = false
    @State private var copiedTableID: Int?
    @Environment(\.openURL) private var openURL

    private enum CachedRegex {
        static let strictTriple = try! NSRegularExpression(pattern: #"(?<!\*)\*{3}([^\*\r\n][^\r\n]*?[^\*\s\r\n]|[^\*\s\r\n])\*{3}(?!\*)"#)
        static let strictDouble = try! NSRegularExpression(pattern: #"(?<!\*)\*{2}([^\*\r\n][^\r\n]*?[^\*\s\r\n]|[^\*\s\r\n])\*{2}(?!\*)"#)
        static let strictSingle = try! NSRegularExpression(pattern: #"(?<!\*)\*{1}([^\*\r\n][^\r\n]*?[^\*\s\r\n]|[^\*\s\r\n])\*{1}(?!\*)"#)
        static let htmlTag = try! NSRegularExpression(pattern: #"<([a-zA-Z][a-zA-Z0-9]*)>([^<]*?)</\1>"#, options: .caseInsensitive)
        static let markdownLink = try! NSRegularExpression(pattern: #"\[[^\]]*\]\([^\)]*\)"#)
        static let httpURL = try! NSRegularExpression(pattern: #"https?://[^\s\)\]<>\"']+"#)
        static let highlight = try! NSRegularExpression(pattern: #"(?<!=)==([^=]+?)==(?!=)"#)
        static let strikethrough = try! NSRegularExpression(pattern: #"(?<!~)~~([^~]+?)~~(?!~)"#)
        static let baseline = try! NSRegularExpression(pattern: #"((?<!~)~([^~\s]+?)~(?!~))|((?<!\^)\^([^\^\s]+?)\^(?!\^))"#)
        static let footnoteRef = try! NSRegularExpression(pattern: #"\[\^[^\]\s]+\]"#)
        static let imageLine = try! NSRegularExpression(pattern: #"^!\[([^\]]*)\]\(\s*([^\s)]+)[^)]*\)$"#)
    }

    private enum ViewMode: String, CaseIterable, Identifiable {
        case preview = "預覽"
        case source = "原文"

        var id: Self { self }
    }

    private enum StickyNoteColor: String, CaseIterable, Identifiable {
        case yellow = "黃"
        case green = "綠"
        case blue = "藍"
        case magenta = "洋紅"

        var id: Self { self }

        var paper: Color {
            switch self {
            case .yellow: Color(red: 1.00, green: 0.94, blue: 0.55)
            case .green: Color(red: 0.78, green: 0.94, blue: 0.72)
            case .blue: Color(red: 0.72, green: 0.87, blue: 0.98)
            case .magenta: Color(red: 0.98, green: 0.72, blue: 0.90)
            }
        }

        var ink: Color {
            switch self {
            case .yellow: Color(red: 0.30, green: 0.24, blue: 0.10)
            case .green: Color(red: 0.15, green: 0.32, blue: 0.18)
            case .blue: Color(red: 0.10, green: 0.24, blue: 0.42)
            case .magenta: Color(red: 0.42, green: 0.12, blue: 0.34)
            }
        }
    }

    private enum ListColor: String, CaseIterable, Identifiable {
        case none = "無色"
        case gray = "灰"
        case mint = "薄荷"
        case sky = "天藍"
        case lavender = "薰衣草"
        case peach = "蜜桃"
        case rose = "玫瑰"
        case lemon = "檸檬"
        case sage = "鼠尾草"
        case coral = "珊瑚"

        var id: Self { self }

        var color: Color? {
            switch self {
            case .none: nil
            case .gray: Color(red: 0.60, green: 0.60, blue: 0.62)
            case .mint: Color(red: 0.53, green: 0.83, blue: 0.72)
            case .sky: Color(red: 0.58, green: 0.79, blue: 0.93)
            case .lavender: Color(red: 0.74, green: 0.70, blue: 0.92)
            case .peach: Color(red: 0.99, green: 0.79, blue: 0.66)
            case .rose: Color(red: 0.96, green: 0.72, blue: 0.78)
            case .lemon: Color(red: 0.98, green: 0.92, blue: 0.60)
            case .sage: Color(red: 0.72, green: 0.84, blue: 0.66)
            case .coral: Color(red: 0.98, green: 0.66, blue: 0.60)
            }
        }

        var swatchColor: Color {
            color ?? Color.white
        }

        /// 0–255 RGB components, used to reproduce the colour in printed HTML.
        var rgb: (r: Int, g: Int, b: Int)? {
            switch self {
            case .none: nil
            case .gray: (153, 153, 158)
            case .mint: (135, 212, 184)
            case .sky: (148, 201, 237)
            case .lavender: (189, 179, 235)
            case .peach: (252, 201, 168)
            case .rose: (245, 184, 199)
            case .lemon: (250, 235, 153)
            case .sage: (184, 214, 168)
            case .coral: (250, 168, 153)
            }
        }
    }

    private enum FontFamily: String, CaseIterable, Identifiable {
        case serif = "襯線體"
        case sansSerif = "非襯線體"

        var id: Self { self }

        var design: Font.Design {
            switch self {
            case .serif: .serif
            case .sansSerif: .default
            }
        }

        var systemImage: String {
            switch self {
            case .serif: "textformat.abc"
            case .sansSerif: "textformat"
            }
        }
    }

    private enum AppearanceMode: String, CaseIterable, Identifiable {
        case system = "系統"
        case light = "淺色"
        case dark = "深色"
        case eyeCare = "護眼"

        var id: Self { self }

        var systemImage: String {
            switch self {
            case .system: "circle.lefthalf.filled"
            case .light: "sun.max"
            case .dark: "moon"
            case .eyeCare: "leaf"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light, .eyeCare: .light
            case .dark: .dark
            }
        }
    }

    private struct MarkdownBlock: Identifiable {
        let id: Int
        let content: MarkdownBlockContent
    }

    private enum MarkdownBlockContent {
        case text(String)
        case heading(MarkdownHeading)
        case code(MarkdownCodeBlock)
        case divider(DividerStyle)
        case table(MarkdownTable)
        case taskList([MarkdownTaskItem])
        case bulletList([MarkdownBulletItem])
        case orderedList([MarkdownOrderedItem])
        case blockQuote(String)
        case image(MarkdownImage)
    }

    private enum DividerStyle {
        case thin       // ---
        case medium     // ___
        case thick      // ***

        var thickness: CGFloat {
            switch self {
            case .thin: 1
            case .medium: 2
            case .thick: 3
            }
        }

        var maxOpacity: Double {
            switch self {
            case .thin: 0.32
            case .medium: 0.48
            case .thick: 0.65
            }
        }
    }

    private struct MarkdownHeading {
        let level: Int
        let text: String
    }

    private struct MarkdownTaskItem {
        let isChecked: Bool
        let text: String
    }

    private struct MarkdownBulletItem {
        let indent: Int
        let text: String
    }

    private struct MarkdownOrderedItem {
        let indent: Int
        let number: Int
        let text: String
    }

    private struct MarkdownCodeBlock {
        let language: String?
        let code: String
    }

    private struct MarkdownImage: Identifiable, Hashable {
        let altText: String
        let urlString: String

        var id: String { urlString }

        var url: URL? { URL(string: urlString) }
    }

    private struct MarkdownTable {
        let header: [String]
        let rows: [[String]]

        var columnCount: Int {
            max(header.count, rows.map(\.count).max() ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    editorView
                } else if markdownText.isEmpty {
                    emptyState
                } else {
                    reader
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle(markdownText.isEmpty ? "" : selectedFileName)
            .navigationSubtitle(markdownText.isEmpty ? "" : fileSummary)
            .safeAreaInset(edge: .bottom) {
                bottomViewModeBar
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("開啟檔案", systemImage: "folder.badge.plus")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingFontStepper = true
                    } label: {
                        Label("字型大小", systemImage: "textformat.size")
                    }
                    .disabled(markdownText.isEmpty)
                    .popover(isPresented: $isShowingFontStepper) {
                        fontControlsPopover
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleEditing()
                    } label: {
                        Label(isEditing ? "完成編輯" : "編輯",
                              systemImage: isEditing ? "checkmark.circle" : "square.and.pencil")
                    }
                    .disabled(markdownText.isEmpty)
                }

                if isEditing {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            saveMarkdownToFile()
                        } label: {
                            Label(didJustSave ? "已儲存" : "儲存",
                                  systemImage: didJustSave ? "checkmark" : "square.and.arrow.down")
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .disabled(currentFileURL == nil)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("外觀模式", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Label(LocalizedStringKey(mode.rawValue), systemImage: mode.systemImage).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)

                        Divider()

                        ShareLink(
                            item: markdownText,
                            subject: Text(selectedFileName),
                            preview: SharePreview(selectedFileName)
                        ) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        .disabled(markdownText.isEmpty)

                        Button {
                            printDocument()
                        } label: {
                            Label("列印", systemImage: "printer")
                        }
                        .disabled(markdownText.isEmpty)

                        Button {
                            isShowingDonation = true
                        } label: {
                            Label("贊助支持", systemImage: "heart")
                        }

                        Button {
                            isShowingSettings = true
                        } label: {
                            Label("設定", systemImage: "gearshape")
                        }
                    } label: {
                        Label("更多", systemImage: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: Self.readableContentTypes,
                allowsMultipleSelection: false,
                onCompletion: handleFileImport
            )
            .sheet(isPresented: $isShowingSettings) {
                settingsView
            }
            .sheet(isPresented: $isShowingDonation) {
                DonationView()
            }
            .alert("檔案錯誤", isPresented: errorAlertBinding) {
                Button("好", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "請確認檔案可讀取後再試一次。")
            }
            .confirmationDialog(
                imageActionTarget?.altText.isEmpty == false
                    ? Text(imageActionTarget?.altText ?? "")
                    : Text("圖片"),
                isPresented: imageActionBinding,
                titleVisibility: .visible,
                presenting: imageActionTarget
            ) { image in
                Button("前往這個網址") {
                    if let url = image.url {
                        openURL(url)
                    }
                }
                if loadedImageURLs.contains(image.urlString) {
                    Button("隱藏圖片") {
                        loadedImageURLs.remove(image.urlString)
                    }
                } else {
                    Button("載入圖片") {
                        loadedImageURLs.insert(image.urlString)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: { image in
                Text(image.urlString)
            }
            .onAppear(perform: loadBundledReadmeIfAvailable)
            .onChange(of: markdownText) { _, newValue in
                // While editing, defer the (relatively heavy) re-parse until the
                // user finishes so typing stays responsive.
                guard !isEditing else { return }
                refreshDerivedContent(for: newValue)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    @ViewBuilder
    private var bottomViewModeBar: some View {
        if !markdownText.isEmpty && !isEditing {
            Picker("閱讀模式", selection: $viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(LocalizedStringKey(mode.rawValue)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(in: .capsule)
            .padding(.bottom, 12)
            .opacity(isBottomBarVisible ? 1 : 0)
            .offset(y: isBottomBarVisible ? 0 : 24)
            .animation(.easeInOut(duration: 0.25), value: isBottomBarVisible)
            .allowsHitTesting(isBottomBarVisible)
        }
    }

    private func revealBottomBarAndScheduleHide() {
        if !isBottomBarVisible {
            isBottomBarVisible = true
        }
        bottomBarHideTask?.cancel()
        bottomBarHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            isBottomBarVisible = false
        }
    }

    @ViewBuilder
    private var pageBackground: some View {
        if appearanceMode == .eyeCare {
            Color(red: 0.97, green: 0.93, blue: 0.83)
        } else {
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.08),
                    Color.gray.opacity(0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("無序清單顏色") {
                    listColorPicker(selection: $unorderedListColor)
                }
                Section("有序清單顏色") {
                    listColorPicker(selection: $orderedListColor)
                }
                Section("表格顏色") {
                    listColorPicker(selection: $tableColor)
                    Toggle("帶狀列顯示", isOn: $tableStripedRows)
                }
                Section("註腳便利貼") {
                    Toggle("顯示便利貼樣式", isOn: $stickyNotesEnabled)
                    stickyNoteColorPicker
                        .disabled(!stickyNotesEnabled)
                }
            }
            .navigationTitle("設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isShowingSettings = false
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 360)
    }

    private var stickyNoteColorPicker: some View {
        HStack(spacing: 12) {
            ForEach(StickyNoteColor.allCases) { option in
                Button {
                    stickyNoteColor = option
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(option.paper)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.35), lineWidth: 0.5)
                            )
                        if stickyNoteColor == option {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2.5)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(option.rawValue)))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func listColorPicker(selection: Binding<ListColor>) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ListColor.allCases) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(option.swatchColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.35), lineWidth: 0.5)
                            )

                        if option == .none {
                            Image(systemName: "slash.circle")
                                .foregroundStyle(Color.secondary)
                        }

                        if selection.wrappedValue == option {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2.5)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(option.rawValue)))
            }
        }
        .padding(.vertical, 4)
    }

    private var fontControlsPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("字型大小")
                .font(.caption)
                .foregroundStyle(.secondary)
            fontSizeStepper

            Divider()

            Text("字型樣式")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("字型樣式", selection: $fontFamily) {
                ForEach(FontFamily.allCases) { family in
                    Text(LocalizedStringKey(family.rawValue)).tag(family)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(markdownText.isEmpty)
        }
        .padding(14)
        .frame(minWidth: 220)
    }

    private var fontSizeStepper: some View {
        HStack(spacing: 0) {
            Button {
                if textSize > 13 { textSize -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .frame(width: 44, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(markdownText.isEmpty || textSize <= 13)

            Divider().frame(height: 16)

            Text("\(Int(textSize))")
                .font(.body.monospacedDigit())
                .frame(minWidth: 36)

            Divider().frame(height: 16)

            Button {
                if textSize < 28 { textSize += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .frame(width: 44, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(markdownText.isEmpty || textSize >= 28)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
        )
        .fixedSize()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("開啟 Markdown 檔案", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("支援 .md、.markdown 與純文字檔案。")
        } actions: {
            Button {
                isShowingFileImporter = true
            } label: {
                Label("選擇檔案", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var reader: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewMode == .preview {
                    ForEach(markdownBlocks) { block in
                        switch block.content {
                        case .text(let text):
                            if stickyNotesEnabled && containsFootnoteReference(text) {
                                stickyNoteView(text)
                            } else {
                                renderInlineMarkdown(text, baseSize: textSize, design: fontFamily.design)
                                    .lineSpacing(textSize * 0.38)
                                    .textSelection(.enabled)
                            }
                        case .heading(let heading):
                            markdownHeadingView(heading)
                        case .code(let codeBlock):
                            markdownCodeBlockView(codeBlock, id: block.id)
                        case .divider(let style):
                            markdownDivider(style)
                        case .table(let table):
                            markdownTableView(table, id: block.id)
                        case .taskList(let items):
                            markdownTaskListView(items)
                        case .bulletList(let items):
                            markdownBulletListView(items)
                        case .orderedList(let items):
                            markdownOrderedListView(items)
                        case .blockQuote(let quoteText):
                            markdownBlockQuoteView(quoteText)
                        case .image(let image):
                            markdownImageView(image)
                        }
                    }
                } else {
                    Text(markdownText)
                        .font(.system(size: textSize, design: .monospaced))
                        .lineSpacing(textSize * 0.28)
                        .textSelection(.enabled)
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: 820, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { readerAvailableWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, newValue in
                            readerAvailableWidth = newValue
                        }
                }
            )
        }
        .scrollContentBackground(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            guard oldValue != newValue else { return }
            revealBottomBarAndScheduleHide()
        }
        .onAppear {
            revealBottomBarAndScheduleHide()
        }
        .onDisappear {
            bottomBarHideTask?.cancel()
        }
    }

    private var editorView: some View {
        TextEditor(text: $markdownText)
            .font(.system(size: textSize, design: .monospaced))
            .lineSpacing(textSize * 0.25)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(iOS)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            #endif
    }

    private func toggleEditing() {
        // When leaving edit mode, refresh the parsed preview content that we
        // deliberately skipped updating while the user was typing.
        if isEditing {
            refreshDerivedContent(for: markdownText)
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing.toggle()
        }
    }

    private func saveMarkdownToFile() {
        guard let url = currentFileURL else { return }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try Data(markdownText.utf8).write(to: url, options: .atomic)
            withAnimation(.easeInOut(duration: 0.2)) {
                didJustSave = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut(duration: 0.2)) {
                    didJustSave = false
                }
            }
        } catch {
            errorMessage = String(localized: "儲存失敗：\(error.localizedDescription)")
        }
    }

    private func computeFileSummary(from text: String) -> String {
        guard !text.isEmpty else {
            return String(localized: "輕量 Markdown 閱讀器")
        }

        let lineCount = text.components(separatedBy: .newlines).count
        let wordCount = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        let characterCount = text.filter { !$0.isNewline }.count

        let lines = lineCount.formatted()
        let words = wordCount.formatted()
        let chars = characterCount.formatted()
        return String(localized: "\(lines) 行 · \(words) 字 · \(chars) 字元")
    }

    private func refreshDerivedContent(for text: String) {
        markdownBlocks = parseMarkdownBlocks(from: text)
        fileSummary = computeFileSummary(from: text)
    }

    private var imageActionBinding: Binding<Bool> {
        Binding(
            get: { imageActionTarget != nil },
            set: { isPresented in
                if !isPresented {
                    imageActionTarget = nil
                }
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private static var readableContentTypes: [UTType] {
        let markdownTypes = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown")
        ].compactMap { $0 }

        return markdownTypes + [.plainText]
    }

    private func copyCodeToClipboard(_ code: String, blockID: Int) {
        writeToClipboard(code)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedCodeBlockID = blockID
        }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedCodeBlockID == blockID {
                    copiedCodeBlockID = nil
                }
            }
        }
    }

    private func writeToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            try loadMarkdownFile(from: url)
            // Remember the user-selected file so edits can be saved back to it.
            currentFileURL = url
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadBundledReadmeIfAvailable() {
        guard markdownText.isEmpty, let url = Bundle.main.url(forResource: "readme", withExtension: "md") else {
            return
        }

        do {
            try loadMarkdownFile(from: url)
            // The bundled sample lives inside the read-only app bundle, so it
            // cannot be saved back to.
            currentFileURL = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMarkdownFile(from url: URL) throws {
        let canAccessFile = url.startAccessingSecurityScopedResource()
        defer {
            if canAccessFile {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let text = String(decoding: data, as: UTF8.self)

        markdownText = text
        selectedFileName = url.lastPathComponent
        tableColumnWidths.removeAll()
        tableDragStartWidths.removeAll()
        tableColorsDisabled.removeAll()
        viewMode = .preview
    }

    private func renderInlineMarkdown(
        _ text: String,
        baseSize: Double,
        design: Font.Design = .default,
        boldByDefault: Bool = false
    ) -> Text {
        let escapeSegments = splitByEscapes(text)
        var combined = Text("")
        for seg in escapeSegments {
            if seg.isEscape {
                let segText = renderEscapedCharacter(
                    seg.text,
                    baseSize: baseSize,
                    design: design,
                    boldByDefault: boldByDefault
                )
                combined = Text("\(combined)\(segText)")
            } else {
                let segText = renderInlineMarkdownPlain(
                    seg.text,
                    baseSize: baseSize,
                    design: design,
                    boldByDefault: boldByDefault
                )
                combined = Text("\(combined)\(segText)")
            }
        }
        return combined
    }

    private struct EscapeSegment {
        let text: String
        let isEscape: Bool
    }

    private func splitByEscapes(_ text: String) -> [EscapeSegment] {
        let nsText = text as NSString
        let specials: Set<Character> = ["*", "_", "`", "\\", "[", "]", "(", ")", "{", "}", "#", "!", "+", "-", ".", "~", "<", ">", "|", "\"", "'"]

        var segments: [EscapeSegment] = []
        var buffer = ""
        var i = 0
        while i < nsText.length {
            let ch = nsText.substring(with: NSRange(location: i, length: 1))
            if ch == "\\" && i + 1 < nsText.length {
                let nextStr = nsText.substring(with: NSRange(location: i + 1, length: 1))
                if let nextChar = nextStr.first, specials.contains(nextChar) {
                    if !buffer.isEmpty {
                        segments.append(EscapeSegment(text: buffer, isEscape: false))
                        buffer = ""
                    }
                    segments.append(EscapeSegment(text: nextStr, isEscape: true))
                    i += 2
                    continue
                }
            }
            buffer.append(ch)
            i += 1
        }
        if !buffer.isEmpty {
            segments.append(EscapeSegment(text: buffer, isEscape: false))
        }
        return segments
    }

    private func renderEscapedCharacter(
        _ character: String,
        baseSize: Double,
        design: Font.Design,
        boldByDefault: Bool
    ) -> Text {
        var attr = AttributedString(character)
        var font = Font.system(size: baseSize, design: design)
        if boldByDefault {
            font = font.bold()
        }
        attr.font = font
        attr.backgroundColor = Color.secondary.opacity(0.22)
        return Text(attr)
    }

    private func renderInlineMarkdownPlain(
        _ text: String,
        baseSize: Double,
        design: Font.Design,
        boldByDefault: Bool
    ) -> Text {
        let strict = applyStrictAsteriskEmphasis(text)
        let preprocessed = autolinkURLs(in: strict)
        let htmlSegments = splitByHTMLTags(preprocessed)

        var result = Text("")
        for htmlSeg in htmlSegments {
            let strikeSegments = splitByStrikethrough(htmlSeg.text)

            for strikeSeg in strikeSegments {
                let highlightSegments = splitByHighlight(strikeSeg.text)

                for hlSeg in highlightSegments {
                    let baselineSegs = splitByBaseline(hlSeg.text)

                    for blSeg in baselineSegs {
                        let segBaseSize: Double
                        let baselineOffset: Double
                        switch blSeg.style {
                        case .normal:
                            segBaseSize = baseSize
                            baselineOffset = 0
                        case .sub:
                            segBaseSize = baseSize * 0.7
                            baselineOffset = -baseSize * 0.22
                        case .sup:
                            segBaseSize = baseSize * 0.7
                            baselineOffset = baseSize * 0.35
                        }

                        var partText: Text
                        if hlSeg.isHighlight {
                            partText = renderHighlightSegment(
                                blSeg.text,
                                baseSize: segBaseSize,
                                design: design,
                                boldByDefault: boldByDefault
                            )
                        } else {
                            partText = renderMarkdownRuns(
                                blSeg.text,
                                baseSize: segBaseSize,
                                design: design,
                                boldByDefault: boldByDefault
                            )
                        }
                        if baselineOffset != 0 {
                            partText = partText.baselineOffset(baselineOffset)
                        }
                        if let color = htmlSeg.color {
                            partText = partText.foregroundColor(color)
                        }
                        if strikeSeg.isStrike {
                            partText = partText.strikethrough(true, color: .red).foregroundColor(.red)
                        }
                        result = Text("\(result)\(partText)")
                    }
                }
            }
        }

        return result
    }

    private struct StrikeSegment {
        let text: String
        let isStrike: Bool
    }

    private struct HighlightSegment {
        let text: String
        let isHighlight: Bool
    }

    private enum BaselineStyle {
        case normal
        case sub
        case sup
    }

    private struct BaselineSegment {
        let text: String
        let style: BaselineStyle
    }

    private struct HTMLSegment {
        let text: String
        let color: Color?
    }

    private func splitByHTMLTags(_ text: String) -> [HTMLSegment] {
        let nsText = text as NSString
        let matches = CachedRegex.htmlTag.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return [HTMLSegment(text: text, color: nil)]
        }

        var segments: [HTMLSegment] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                let before = nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                if !before.isEmpty {
                    segments.append(HTMLSegment(text: before, color: nil))
                }
            }
            let tagName = nsText.substring(with: match.range(at: 1))
            let content = nsText.substring(with: match.range(at: 2))
            let color = brightColor(for: tagName.lowercased())
            segments.append(HTMLSegment(text: content, color: color))
            cursor = match.range.location + match.range.length
        }
        if cursor < nsText.length {
            let after = nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor))
            if !after.isEmpty {
                segments.append(HTMLSegment(text: after, color: nil))
            }
        }
        return segments
    }

    private func brightColor(for key: String) -> Color {
        let palette: [Color] = [.red, .orange, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink]
        let hash = abs(key.hashValue)
        return palette[hash % palette.count]
    }

    private func splitByBaseline(_ text: String) -> [BaselineSegment] {
        let nsText = text as NSString

        let linkMatches = CachedRegex.markdownLink.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        let protectedRanges = linkMatches.map { $0.range }

        let matches = CachedRegex.baseline.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        let filtered = matches.filter { match in
            !protectedRanges.contains { NSIntersectionRange($0, match.range).length > 0 }
        }
        guard !filtered.isEmpty else {
            return [BaselineSegment(text: text, style: .normal)]
        }

        var segments: [BaselineSegment] = []
        var cursor = 0
        for match in filtered {
            if match.range.location > cursor {
                let before = nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                if !before.isEmpty {
                    segments.append(BaselineSegment(text: before, style: .normal))
                }
            }
            let subRange = match.range(at: 2)
            let supRange = match.range(at: 4)
            if subRange.location != NSNotFound {
                segments.append(BaselineSegment(text: nsText.substring(with: subRange), style: .sub))
            } else if supRange.location != NSNotFound {
                segments.append(BaselineSegment(text: nsText.substring(with: supRange), style: .sup))
            }
            cursor = match.range.location + match.range.length
        }
        if cursor < nsText.length {
            let after = nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor))
            if !after.isEmpty {
                segments.append(BaselineSegment(text: after, style: .normal))
            }
        }
        return segments
    }

    private func splitByHighlight(_ text: String) -> [HighlightSegment] {
        let nsText = text as NSString
        let matches = CachedRegex.highlight.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return [HighlightSegment(text: text, isHighlight: false)]
        }

        var segments: [HighlightSegment] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                let before = nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                if !before.isEmpty {
                    segments.append(HighlightSegment(text: before, isHighlight: false))
                }
            }
            let content = nsText.substring(with: match.range(at: 1))
            segments.append(HighlightSegment(text: content, isHighlight: true))
            cursor = match.range.location + match.range.length
        }
        if cursor < nsText.length {
            let after = nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor))
            if !after.isEmpty {
                segments.append(HighlightSegment(text: after, isHighlight: false))
            }
        }
        return segments
    }

    private func renderHighlightSegment(
        _ text: String,
        baseSize: Double,
        design: Font.Design,
        boldByDefault: Bool
    ) -> Text {
        let highlightColor = Color.yellow.opacity(0.55)
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)

        guard var attributed = try? AttributedString(markdown: text, options: options) else {
            var attr = AttributedString(text)
            attr.font = Font.system(size: baseSize, design: design)
            attr.backgroundColor = highlightColor
            return Text(attr)
        }

        for run in attributed.runs {
            let intent = run.inlinePresentationIntent ?? []
            let isCode = intent.contains(.code)
            var font = Font.system(size: baseSize, design: isCode ? .monospaced : design)
            if boldByDefault || intent.contains(.stronglyEmphasized) {
                font = font.bold()
            }
            if intent.contains(.emphasized) {
                font = font.italic()
            }
            attributed[run.range].font = font
            attributed[run.range].backgroundColor = highlightColor

            if run.link != nil {
                attributed[run.range].foregroundColor = .blue
                let segStr = String(attributed[run.range].characters)
                if segStr.hasPrefix("http://") || segStr.hasPrefix("https://") {
                    attributed[run.range].underlineStyle = .single
                }
            }
        }

        return Text(attributed)
    }

    private func splitByStrikethrough(_ text: String) -> [StrikeSegment] {
        let nsText = text as NSString
        let matches = CachedRegex.strikethrough.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return [StrikeSegment(text: text, isStrike: false)]
        }

        var segments: [StrikeSegment] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                let before = nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                if !before.isEmpty {
                    segments.append(StrikeSegment(text: before, isStrike: false))
                }
            }
            let content = nsText.substring(with: match.range(at: 1))
            segments.append(StrikeSegment(text: content, isStrike: true))
            cursor = match.range.location + match.range.length
        }
        if cursor < nsText.length {
            let after = nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor))
            if !after.isEmpty {
                segments.append(StrikeSegment(text: after, isStrike: false))
            }
        }
        return segments
    }

    private func renderMarkdownRuns(
        _ text: String,
        baseSize: Double,
        design: Font.Design,
        boldByDefault: Bool
    ) -> Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        guard let attributed = try? AttributedString(markdown: text, options: options) else {
            return Text(text).font(.system(size: baseSize, design: design))
        }

        var result = Text("")
        let linkIconSize = baseSize * 0.75

        for run in attributed.runs {
            let segment = String(attributed[run.range].characters)
            let intent = run.inlinePresentationIntent ?? []
            let isCode = intent.contains(.code)

            if let url = run.link {
                var linkAttr = AttributedString(segment)
                linkAttr.link = url
                linkAttr.foregroundColor = .blue
                if segment.hasPrefix("http://") || segment.hasPrefix("https://") {
                    linkAttr.underlineStyle = .single
                }
                linkAttr.font = Font.system(size: baseSize, design: design)

                let iconText = Text(Image(systemName: "hand.point.up.left.fill"))
                    .font(.system(size: linkIconSize))
                    .foregroundColor(.blue)

                let linkText = Text(linkAttr)
                let spacer = Text("\u{2009}")
                result = Text("\(result)\(linkText)\(spacer)\(iconText)")
                continue
            }

            var part = Text(segment)
                .font(.system(size: baseSize, design: isCode ? .monospaced : design))

            if boldByDefault || intent.contains(.stronglyEmphasized) {
                part = part.bold()
            }
            if intent.contains(.emphasized) {
                part = part.italic()
            }

            result = Text("\(result)\(part)")
        }

        return result
    }

    private func applyStrictAsteriskEmphasis(_ text: String) -> String {
        var escaped = ""
        for ch in text {
            if ch == "_" {
                escaped.append("\\_")
            } else {
                escaped.append(ch)
            }
        }

        let ns = escaped as NSString
        let regexes = [CachedRegex.strictTriple, CachedRegex.strictDouble, CachedRegex.strictSingle]

        var protectedRanges: [NSRange] = []
        for regex in regexes {
            let matches = regex.matches(in: escaped, options: [], range: NSRange(location: 0, length: ns.length))
            for match in matches {
                let range = match.range
                let overlaps = protectedRanges.contains { NSIntersectionRange($0, range).length > 0 }
                if !overlaps {
                    protectedRanges.append(range)
                }
            }
        }

        var result = ""
        result.reserveCapacity(escaped.count)
        for index in 0..<ns.length {
            let charRange = NSRange(location: index, length: 1)
            let ch = ns.substring(with: charRange)
            if ch == "*" {
                let inside = protectedRanges.contains { NSLocationInRange(index, $0) }
                if inside {
                    result.append(ch)
                } else {
                    result.append("\\*")
                }
            } else {
                result.append(ch)
            }
        }
        return result
    }

    private func autolinkURLs(in text: String) -> String {
        let nsText = text as NSString

        let linkMatches = CachedRegex.markdownLink.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        let protectedRanges = linkMatches.map { $0.range }

        let urlMatches = CachedRegex.httpURL.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        let candidates = urlMatches.filter { match in
            !protectedRanges.contains { range in
                NSIntersectionRange(range, match.range).length > 0
            }
        }

        var result = text
        for match in candidates.reversed() {
            var url = nsText.substring(with: match.range)
            while let last = url.last, ".,!?;:".contains(last) {
                url.removeLast()
            }
            guard !url.isEmpty else { continue }
            let trimmedLength = (url as NSString).length
            let adjustedRange = NSRange(location: match.range.location, length: trimmedLength)
            guard let stringRange = Range(adjustedRange, in: result) else { continue }
            result.replaceSubrange(stringRange, with: "[\(url)](\(url))")
        }
        return result
    }

    private func markdownTableView(_ table: MarkdownTable, id: Int) -> some View {
        let columnWidth = tableColumnWidth(for: id, columnCount: table.columnCount)

        return VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: true) {
                Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        ForEach(0..<table.columnCount, id: \.self) { column in
                            tableCell(
                                table.header[safe: column] ?? "",
                                isHeader: true,
                                rowIndex: 0,
                                columnWidth: columnWidth,
                                tableID: id
                            )
                        }
                    }

                    ForEach(table.rows.indices, id: \.self) { rowIndex in
                        GridRow {
                            ForEach(0..<table.columnCount, id: \.self) { column in
                                tableCell(
                                    table.rows[rowIndex][safe: column] ?? "",
                                    isHeader: false,
                                    rowIndex: rowIndex,
                                    columnWidth: columnWidth,
                                    tableID: id
                                )
                            }
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tableGridColor(for: id), lineWidth: 1)
                )
                .padding(.bottom, 8)
            }

            tableControls(for: id, columnWidth: columnWidth, table: table)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownBlockQuoteView(_ quoteText: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            renderInlineMarkdown(quoteText, baseSize: textSize, design: fontFamily.design)
                .lineSpacing(textSize * 0.32)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\u{201D}")
                .font(.system(size: textSize * 2.4, design: .serif).weight(.bold))
                .foregroundStyle(Color(white: 0.3))
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 4)
        .overlay(alignment: .topLeading) {
            Text("\u{201C}")
                .font(.system(size: textSize * 2.4, design: .serif).weight(.bold))
                .foregroundStyle(Color(white: 0.3))
                .offset(x: 14, y: -textSize * 0.35)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func markdownImageView(_ image: MarkdownImage) -> some View {
        if loadedImageURLs.contains(image.urlString), let url = image.url {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        imageLoadingCard(image)
                    case .success(let loaded):
                        loaded
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    case .failure:
                        imageAttachmentCard(image, failed: true)
                    @unknown default:
                        imageAttachmentCard(image, failed: false)
                    }
                }

                if !image.altText.isEmpty {
                    Text(image.altText)
                        .font(.system(size: max(textSize - 3, 11), design: fontFamily.design))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture { imageActionTarget = image }
        } else {
            imageAttachmentCard(image, failed: false)
                .onTapGesture { imageActionTarget = image }
        }
    }

    private func imageAttachmentCard(_ image: MarkdownImage, failed: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: failed ? "photo.badge.exclamationmark" : "photo")
                .font(.system(size: textSize * 1.4))
                .foregroundStyle(failed ? Color.orange : Color.accentColor)
                .frame(width: textSize * 2.2, height: textSize * 2.2)

            VStack(alignment: .leading, spacing: 4) {
                Text(image.altText.isEmpty ? String(localized: "圖片附件") : image.altText)
                    .font(.system(size: textSize, design: fontFamily.design).weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(image.urlString)
                    .font(.system(size: max(textSize - 4, 10), design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(failed ? "無法載入圖片，點一下查看選項" : "點一下圖片以查看選項")
                    .font(.system(size: max(textSize - 5, 9)))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func imageLoadingCard(_ image: MarkdownImage) -> some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("載入圖片中…")
                .font(.system(size: max(textSize - 2, 12)))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: textSize * 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func markdownBulletListView(_ items: [MarkdownBulletItem]) -> some View {
        let tint = unorderedListColor.color
        return VStack(alignment: .leading, spacing: textSize * 0.4) {
            ForEach(items.indices, id: \.self) { index in
                markdownBulletItemView(items[index])
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((tint ?? Color.clear).opacity(tint == nil ? 0 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke((tint ?? Color.clear).opacity(tint == nil ? 0 : 0.35), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownBulletItemView(_ item: MarkdownBulletItem) -> some View {
        let tint = unorderedListColor.color
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(item.indent > 0 ? "-" : "•")
                .font(.system(size: textSize * 1.2))
                .foregroundStyle((tint ?? Color.secondary).opacity(tint == nil ? 0.8 : 0.9))

            renderInlineMarkdown(item.text, baseSize: textSize, design: fontFamily.design)
                .lineSpacing(textSize * 0.28)
                .textSelection(.enabled)
        }
        .padding(.leading, CGFloat(item.indent) * 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownOrderedListView(_ items: [MarkdownOrderedItem]) -> some View {
        let tint = orderedListColor.color
        return VStack(alignment: .leading, spacing: textSize * 0.4) {
            ForEach(items.indices, id: \.self) { index in
                markdownOrderedItemView(items[index])
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((tint ?? Color.clear).opacity(tint == nil ? 0 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke((tint ?? Color.clear).opacity(tint == nil ? 0 : 0.30), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownOrderedItemView(_ item: MarkdownOrderedItem) -> some View {
        let tint = orderedListColor.color
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(item.number).")
                .font(.system(size: textSize, design: fontFamily.design).weight(.semibold))
                .foregroundStyle((tint ?? Color.secondary).opacity(tint == nil ? 0.8 : 0.85))
                .frame(minWidth: textSize * 1.6, alignment: .trailing)

            renderInlineMarkdown(item.text, baseSize: textSize, design: fontFamily.design)
                .lineSpacing(textSize * 0.28)
                .textSelection(.enabled)
        }
        .padding(.leading, CGFloat(item.indent) * 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownTaskListView(_ items: [MarkdownTaskItem]) -> some View {
        let paperColor = Color(red: 0.995, green: 0.98, blue: 0.90)
        let redMarginColor = Color(red: 0.82, green: 0.22, blue: 0.28).opacity(0.75)
        let blueRuleColor = Color(red: 0.30, green: 0.50, blue: 0.85).opacity(0.55)
        let inkColor = Color(red: 0.15, green: 0.22, blue: 0.42)
        let checkedInk = Color(red: 0.45, green: 0.45, blue: 0.55)

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: items[index].isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: textSize * 0.95))
                        .foregroundStyle(items[index].isChecked ? Color(red: 0.15, green: 0.55, blue: 0.35) : inkColor.opacity(0.6))
                        .symbolRenderingMode(.hierarchical)

                    renderInlineMarkdown(items[index].text, baseSize: textSize, design: .default)
                        .lineSpacing(textSize * 0.28)
                        .textSelection(.enabled)
                        .strikethrough(items[index].isChecked, color: checkedInk)
                        .foregroundStyle(items[index].isChecked ? checkedInk : inkColor)

                    Spacer(minLength: 0)
                }
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .padding(.vertical, textSize * 0.42)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(blueRuleColor)
                        .frame(height: 0.7)
                }
            }
        }
        .padding(.leading, 30)
        .background(paperColor)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(redMarginColor)
                .frame(width: 1.4)
                .padding(.leading, 22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func containsFootnoteReference(_ text: String) -> Bool {
        let ns = text as NSString
        return CachedRegex.footnoteRef.firstMatch(
            in: text, options: [], range: NSRange(location: 0, length: ns.length)
        ) != nil
    }

    private func stickyNoteView(_ text: String) -> some View {
        renderInlineMarkdown(text, baseSize: textSize, design: .default)
            .lineSpacing(textSize * 0.30)
            .textSelection(.enabled)
            .foregroundStyle(stickyNoteColor.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(stickyNoteColor.paper)
            )
            .shadow(color: .black.opacity(0.18), radius: 6, x: 2, y: 4)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markdownHeadingView(_ heading: MarkdownHeading) -> some View {
        let size = headingSize(for: heading.level)
        return renderInlineMarkdown(
            heading.text,
            baseSize: size,
            design: fontFamily.design,
            boldByDefault: true
        )
            .lineSpacing(size * 0.18)
            .foregroundStyle(heading.level >= 6 ? .secondary : .primary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, headingTopPadding(for: heading.level))
            .padding(.bottom, headingBottomPadding(for: heading.level))
            .overlay(alignment: .bottom) {
                if heading.level <= 2 {
                    Rectangle()
                        .fill(Color.secondary.opacity(heading.level == 1 ? 0.28 : 0.16))
                        .frame(height: heading.level == 1 ? 1.5 : 1)
                }
            }
    }

    private func headingSize(for level: Int) -> Double {
        switch level {
        case 1: return textSize * 2.0
        case 2: return textSize * 1.6
        case 3: return textSize * 1.35
        case 4: return textSize * 1.18
        case 5: return textSize * 1.05
        default: return textSize
        }
    }

    private func headingTopPadding(for level: Int) -> Double {
        switch level {
        case 1: return 12
        case 2: return 10
        case 3: return 6
        default: return 2
        }
    }

    private func headingBottomPadding(for level: Int) -> Double {
        switch level {
        case 1, 2: return 6
        default: return 2
        }
    }

    private func markdownDivider(_ style: DividerStyle) -> some View {
        RoundedRectangle(cornerRadius: style.thickness / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.08),
                        Color.secondary.opacity(style.maxOpacity),
                        Color.secondary.opacity(0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: style.thickness)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
    }

    private static let codeKeywords: Set<String> = [
        // Swift
        "func", "let", "var", "if", "else", "guard", "return", "class", "struct",
        "enum", "protocol", "extension", "import", "public", "private", "internal",
        "fileprivate", "open", "static", "final", "override", "init", "deinit",
        "self", "Self", "super", "nil", "true", "false", "throws", "throw", "try",
        "catch", "do", "switch", "case", "default", "break", "continue", "for",
        "while", "repeat", "in", "where", "as", "is", "typealias", "associatedtype",
        "inout", "lazy", "weak", "unowned", "willSet", "didSet", "async", "await",
        "some", "any", "mutating", "convenience", "required", "indirect", "defer",
        // JS / TS
        "function", "const", "new", "typeof", "instanceof", "delete", "void",
        "yield", "export", "from", "of", "null", "undefined", "this",
        // Python
        "def", "lambda", "None", "True", "False", "and", "or", "not", "elif", "pass",
        "with", "global", "nonlocal", "raise", "except", "finally", "assert",
        // Common
        "int", "float", "double", "bool", "string", "char", "byte", "long", "short"
    ]

    private func highlightCode(_ code: String, fontSize: Double) -> AttributedString {
        let font = Font.system(size: fontSize, design: .monospaced)
        let plainText = Color(red: 0.86, green: 0.92, blue: 1.0)
        let commentColor = Color(red: 0.42, green: 0.48, blue: 0.53)
        let stringColor = Color(red: 0.98, green: 0.41, blue: 0.36)
        let numberColor = Color(red: 0.82, green: 0.75, blue: 0.41)
        let keywordColor = Color(red: 0.98, green: 0.37, blue: 0.64)
        let typeColor = Color(red: 0.36, green: 0.84, blue: 1.0)

        func makeSegment(_ str: String, color: Color) -> AttributedString {
            var seg = AttributedString(str)
            seg.font = font
            seg.foregroundColor = color
            return seg
        }

        var result = AttributedString()
        let chars = Array(code)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            // Line comment
            if c == "/", i + 1 < chars.count, chars[i + 1] == "/" {
                var j = i
                while j < chars.count, chars[j] != "\n" {
                    j += 1
                }
                result += makeSegment(String(chars[i..<j]), color: commentColor)
                i = j
                continue
            }

            // Block comment
            if c == "/", i + 1 < chars.count, chars[i + 1] == "*" {
                var j = i + 2
                while j < chars.count {
                    if chars[j] == "*", j + 1 < chars.count, chars[j + 1] == "/" {
                        j += 2
                        break
                    }
                    j += 1
                }
                result += makeSegment(String(chars[i..<j]), color: commentColor)
                i = j
                continue
            }

            // Hash comment (Python / Shell)
            if c == "#" {
                var j = i
                while j < chars.count, chars[j] != "\n" {
                    j += 1
                }
                result += makeSegment(String(chars[i..<j]), color: commentColor)
                i = j
                continue
            }

            // String literal (double or single quote, with escape)
            if c == "\"" || c == "'" {
                let quote = c
                var j = i + 1
                while j < chars.count {
                    if chars[j] == "\\", j + 1 < chars.count {
                        j += 2
                        continue
                    }
                    if chars[j] == quote {
                        j += 1
                        break
                    }
                    if chars[j] == "\n" { break }
                    j += 1
                }
                result += makeSegment(String(chars[i..<j]), color: stringColor)
                i = j
                continue
            }

            // Number
            if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." {
                    j += 1
                }
                result += makeSegment(String(chars[i..<j]), color: numberColor)
                i = j
                continue
            }

            // Identifier / keyword / type
            if c.isLetter || c == "_" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" {
                    j += 1
                }
                let ident = String(chars[i..<j])
                let color: Color
                if Self.codeKeywords.contains(ident) {
                    color = keywordColor
                } else if ident.first?.isUppercase == true {
                    color = typeColor
                } else {
                    color = plainText
                }
                result += makeSegment(ident, color: color)
                i = j
                continue
            }

            // Everything else — punctuation / whitespace
            result += makeSegment(String(c), color: plainText)
            i += 1
        }

        return result
    }

    private func markdownCodeBlockView(_ codeBlock: MarkdownCodeBlock, id: Int) -> some View {
        let isCopied = copiedCodeBlockID == id

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if let language = codeBlock.language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(Color(red: 0.62, green: 0.84, blue: 1.0))
                }

                Spacer(minLength: 0)

                Button {
                    copyCodeToClipboard(codeBlock.code, blockID: id)
                } label: {
                    Label {
                        Text(isCopied ? "已複製" : "複製")
                    } icon: {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .frame(width: 12, height: 12)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .font(.caption.weight(.medium))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color(red: 0.86, green: 0.92, blue: 1.0))
                    .frame(height: 14)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 40)
            .background(Color.white.opacity(0.06))

            ScrollView(.horizontal, showsIndicators: true) {
                Text(highlightCode(codeBlock.code, fontSize: max(textSize - 1, 12)))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableControls(for id: Int, columnWidth: Double, table: MarkdownTable) -> some View {
        HStack(spacing: 8) {
            tableResizeHandle(for: id, columnWidth: columnWidth)

            Button {
                if tableColorsDisabled.contains(id) {
                    tableColorsDisabled.remove(id)
                } else {
                    tableColorsDisabled.insert(id)
                }
            } label: {
                Image(systemName: tableColorsDisabled.contains(id) ? "paintpalette" : "paintpalette.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help(tableColorsDisabled.contains(id) ? "還原表格背景色" : "清除表格背景色")

            Button {
                copyTable(id: id, table: table)
            } label: {
                Label {
                    Text(copiedTableID == id ? "已複製" : "複製")
                } icon: {
                    Image(systemName: copiedTableID == id ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                }
                .font(.caption2.weight(.medium))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.10))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("複製表格")
        }
    }

    private func copyTable(id: Int, table: MarkdownTable) {
        // Put both a rich HTML table and a tab-separated fallback on the
        // clipboard. Word and Excel prefer the HTML and paste it as a real
        // table; plain-text editors fall back to the TSV.
        writeTableToPasteboard(
            html: tableClipboardHTML(id: id, table: table),
            plain: tsvRepresentation(of: table)
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedTableID = id
        }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedTableID == id {
                    copiedTableID = nil
                }
            }
        }
    }

    private func writeTableToPasteboard(html: String, plain: String) {
        #if canImport(UIKit)
        UIPasteboard.general.items = [[
            "public.html": html,
            "public.utf8-plain-text": plain
        ]]
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(html, forType: .html)
        pasteboard.setString(plain, forType: .string)
        #endif
    }

    /// A self-contained HTML table that mirrors the table's on-screen state so
    /// it pastes cleanly as a table in both word processors and spreadsheets.
    /// When the table's background colour has been cleared ("無格式"), the copy
    /// keeps only the borders; otherwise it reflects the current colour and
    /// banded-row settings.
    private func tableClipboardHTML(id: Int, table: MarkdownTable) -> String {
        let count = table.columnCount
        let cleared = tableColorsDisabled.contains(id)
        let tint = tableColor.rgb
        let borderHex = cleared ? "#4d4d4d" : "#b8b8b8"
        let cellBase = "border:1px solid \(borderHex);padding:6px 10px;text-align:left;vertical-align:top;"

        // Word ignores rgba() alpha, so pre-blend each tint against a white
        // background into an opaque hex colour it will actually render.
        func blend(_ rgb: (r: Int, g: Int, b: Int), _ alpha: Double) -> String {
            func channel(_ component: Int) -> Int {
                Int((Double(component) * alpha + 255 * (1 - alpha)).rounded())
            }
            return String(format: "#%02X%02X%02X", channel(rgb.r), channel(rgb.g), channel(rgb.b))
        }

        func headerHex() -> String {
            if cleared { return "" }
            if let tint { return blend(tint, 0.75) }
            return blend((128, 128, 128), 0.18)
        }

        func rowHex(_ index: Int) -> String {
            if cleared { return "" }
            if let tint {
                if !tableStripedRows { return blend(tint, 0.14) }
                return index % 2 == 0 ? blend(tint, 0.10) : blend(tint, 0.22)
            }
            if !tableStripedRows { return "" }
            return index % 2 == 0 ? "" : blend((128, 128, 128), 0.10)
        }

        // Emit both a `bgcolor` attribute and an inline style for the widest
        // word-processor / spreadsheet compatibility.
        func cell(_ tag: String, hex: String, extraStyle: String, content: String) -> String {
            let bgAttribute = hex.isEmpty ? "" : " bgcolor=\"\(hex)\""
            let bgStyle = hex.isEmpty ? "" : "background-color:\(hex);"
            return "<\(tag)\(bgAttribute) style=\"\(cellBase)\(extraStyle)\(bgStyle)\">\(content)</\(tag)>"
        }

        var rows = "<tr>"
        for column in 0..<count {
            rows += cell("th", hex: headerHex(), extraStyle: "font-weight:600;", content: inlineHTML(table.header[safe: column] ?? ""))
        }
        rows += "</tr>"

        for (index, tableRow) in table.rows.enumerated() {
            rows += "<tr>"
            for column in 0..<count {
                rows += cell("td", hex: rowHex(index), extraStyle: "", content: inlineHTML(tableRow[safe: column] ?? ""))
            }
            rows += "</tr>"
        }

        return "<html><body><table border=\"1\" cellspacing=\"0\" style=\"border-collapse:collapse;\">\(rows)</table></body></html>"
    }

    private func tsvRepresentation(of table: MarkdownTable) -> String {
        let count = table.columnCount

        func row(_ cells: [String]) -> String {
            (0..<count).map { cells[safe: $0] ?? "" }.joined(separator: "\t")
        }

        var lines: [String] = [row(table.header)]
        for tableRow in table.rows {
            lines.append(row(tableRow))
        }
        return lines.joined(separator: "\n")
    }

    private func tableResizeHandle(for id: Int, columnWidth: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.and.right")
                .font(.caption2.weight(.semibold))

            Text("\(Int(columnWidth))")
                .font(.caption2.monospacedDigit())
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.10))
        .clipShape(Capsule())
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if tableDragStartWidths[id] == nil {
                        tableDragStartWidths[id] = columnWidth
                    }

                    let startWidth = tableDragStartWidths[id] ?? columnWidth
                    tableColumnWidths[id] = clampedTableColumnWidth(startWidth + value.translation.width)
                }
                .onEnded { _ in
                    tableDragStartWidths[id] = nil
                }
        )
    }

    private func tableCell(
        _ value: String,
        isHeader: Bool,
        rowIndex: Int,
        columnWidth: Double,
        tableID: Int
    ) -> some View {
        renderInlineMarkdown(
            value,
            baseSize: max(textSize - 1, 12),
            design: .default,
            boldByDefault: isHeader
        )
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .textSelection(.enabled)
            .frame(width: tableContentWidth(for: columnWidth), alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: columnWidth, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(tableCellBackground(isHeader: isHeader, rowIndex: rowIndex, tableID: tableID))
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(tableGridColor(for: tableID))
                    .frame(width: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(tableGridColor(for: tableID))
                    .frame(height: 1)
            }
    }

    private func tableGridColor(for tableID: Int) -> Color {
        tableColorsDisabled.contains(tableID)
            ? Color(white: 0.30)
            : Color.secondary.opacity(0.18)
    }

    private func tableCellBackground(isHeader: Bool, rowIndex: Int, tableID: Int) -> Color {
        let cleared = tableColorsDisabled.contains(tableID)
        let base = tableColor.color

        if cleared {
            return Color.clear
        }

        if base == nil {
            if isHeader { return Color.secondary.opacity(0.12) }
            if !tableStripedRows { return Color.clear }
            return rowIndex % 2 == 0 ? Color.clear : Color.secondary.opacity(0.06)
        }

        guard let tint = base else { return Color.clear }
        if isHeader {
            return tint.opacity(0.75)
        }
        if !tableStripedRows {
            return tint.opacity(0.14)
        }
        return rowIndex % 2 == 0 ? tint.opacity(0.10) : tint.opacity(0.22)
    }

    private func tableColumnWidth(for id: Int, columnCount: Int) -> Double {
        tableColumnWidths[id] ?? defaultTableColumnWidth(columnCount: columnCount)
    }

    private func defaultTableColumnWidth(columnCount: Int) -> Double {
        let usable = max(Double(readerAvailableWidth) - 48, 200)
        let auto = usable / Double(max(columnCount, 1))
        return clampedTableColumnWidth(auto)
    }

    private func tableContentWidth(for columnWidth: Double) -> Double {
        max(columnWidth - 24, 96)
    }

    private func clampedTableColumnWidth(_ width: Double) -> Double {
        min(max(width, 50), 500)
    }

    private func parseMarkdownBlocks(from markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: .newlines)
        var blocks: [MarkdownBlock] = []
        var textBuffer: [String] = []
        var index = 0

        func flushTextBuffer() {
            let text = textBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(MarkdownBlock(id: blocks.count, content: .text(text)))
            }
            textBuffer.removeAll()
        }

        while index < lines.count {
            let line = lines[index]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("```") {
                flushTextBuffer()

                let language = parseCodeFenceLanguage(from: trimmedLine)
                index += 1

                var codeLines: [String] = []
                while index < lines.count {
                    let codeLine = lines[index]
                    let trimmedCodeLine = codeLine.trimmingCharacters(in: .whitespaces)

                    if trimmedCodeLine.hasPrefix("```") {
                        index += 1
                        break
                    }

                    codeLines.append(codeLine)
                    index += 1
                }

                blocks.append(
                    MarkdownBlock(
                        id: blocks.count,
                        content: .code(MarkdownCodeBlock(language: language, code: codeLines.joined(separator: "\n")))
                    )
                )
                continue
            }

            if let dividerStyle = horizontalRuleStyle(trimmedLine) {
                flushTextBuffer()
                blocks.append(MarkdownBlock(id: blocks.count, content: .divider(dividerStyle)))
                index += 1
                continue
            }

            if index + 1 < lines.count,
               isTableRow(line),
               isTableSeparator(lines[index + 1]) {
                flushTextBuffer()

                let header = parseTableCells(line)
                index += 2

                var rows: [[String]] = []
                while index < lines.count, isTableRow(lines[index]) {
                    rows.append(parseTableCells(lines[index]))
                    index += 1
                }

                blocks.append(MarkdownBlock(id: blocks.count, content: .table(MarkdownTable(header: header, rows: rows))))
                continue
            }

            if trimmedLine.hasPrefix(">") {
                flushTextBuffer()

                var quoteLines: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    guard l.hasPrefix(">") else { break }
                    let content = String(l.dropFirst()).trimmingCharacters(in: .whitespaces)
                    quoteLines.append(content)
                    index += 1
                }

                let quoteText = quoteLines.joined(separator: "\n")
                blocks.append(MarkdownBlock(id: blocks.count, content: .blockQuote(quoteText)))
                continue
            }

            if let heading = parseHeading(from: trimmedLine) {
                flushTextBuffer()
                blocks.append(MarkdownBlock(id: blocks.count, content: .heading(heading)))
                index += 1
                continue
            }

            if let task = parseTaskItem(from: trimmedLine) {
                flushTextBuffer()
                var items: [MarkdownTaskItem] = [task]
                index += 1
                while index < lines.count,
                      let next = parseTaskItem(from: lines[index].trimmingCharacters(in: .whitespaces)) {
                    items.append(next)
                    index += 1
                }
                blocks.append(MarkdownBlock(id: blocks.count, content: .taskList(items)))
                continue
            }

            if let bullet = parseBulletItem(from: line) {
                flushTextBuffer()
                var items: [MarkdownBulletItem] = [bullet]
                index += 1
                while index < lines.count,
                      parseTaskItem(from: lines[index].trimmingCharacters(in: .whitespaces)) == nil,
                      let next = parseBulletItem(from: lines[index]) {
                    items.append(next)
                    index += 1
                }
                blocks.append(MarkdownBlock(id: blocks.count, content: .bulletList(items)))
                continue
            }

            if let ordered = parseOrderedItem(from: line) {
                flushTextBuffer()
                var items: [MarkdownOrderedItem] = [ordered]
                index += 1
                while index < lines.count, let next = parseOrderedItem(from: lines[index]) {
                    items.append(next)
                    index += 1
                }
                blocks.append(MarkdownBlock(id: blocks.count, content: .orderedList(items)))
                continue
            }

            if let image = parseImageLine(from: trimmedLine) {
                flushTextBuffer()
                blocks.append(MarkdownBlock(id: blocks.count, content: .image(image)))
                index += 1
                continue
            }

            textBuffer.append(line)
            index += 1
        }

        flushTextBuffer()
        return blocks
    }

    private func parseImageLine(from trimmedLine: String) -> MarkdownImage? {
        let ns = trimmedLine as NSString
        guard let match = CachedRegex.imageLine.firstMatch(
            in: trimmedLine,
            options: [],
            range: NSRange(location: 0, length: ns.length)
        ) else {
            return nil
        }

        let altRange = match.range(at: 1)
        let urlRange = match.range(at: 2)
        guard urlRange.location != NSNotFound else { return nil }

        let alt = altRange.location != NSNotFound ? ns.substring(with: altRange) : ""
        let urlString = ns.substring(with: urlRange)
        guard !urlString.isEmpty else { return nil }

        return MarkdownImage(
            altText: alt.trimmingCharacters(in: .whitespaces),
            urlString: urlString
        )
    }

    private func parseOrderedItem(from rawLine: String) -> MarkdownOrderedItem? {
        var indent = 0
        var iterator = rawLine.startIndex
        while iterator < rawLine.endIndex {
            let char = rawLine[iterator]
            if char == " " {
                indent += 1
            } else if char == "\t" {
                indent += 4
            } else {
                break
            }
            iterator = rawLine.index(after: iterator)
        }

        var digits = ""
        while iterator < rawLine.endIndex, rawLine[iterator].isNumber {
            digits.append(rawLine[iterator])
            iterator = rawLine.index(after: iterator)
        }

        guard !digits.isEmpty, let number = Int(digits) else { return nil }

        guard iterator < rawLine.endIndex else { return nil }
        let punct = rawLine[iterator]
        guard punct == "." || punct == ")" else { return nil }
        iterator = rawLine.index(after: iterator)

        guard iterator < rawLine.endIndex, rawLine[iterator].isWhitespace else { return nil }
        while iterator < rawLine.endIndex, rawLine[iterator].isWhitespace {
            iterator = rawLine.index(after: iterator)
        }

        let text = String(rawLine[iterator...]).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        return MarkdownOrderedItem(indent: indent / 2, number: number, text: text)
    }

    private func parseBulletItem(from rawLine: String) -> MarkdownBulletItem? {
        let bullets: Set<Character> = ["-", "*", "+"]

        var indent = 0
        var iterator = rawLine.startIndex
        while iterator < rawLine.endIndex {
            let char = rawLine[iterator]
            if char == " " {
                indent += 1
            } else if char == "\t" {
                indent += 4
            } else {
                break
            }
            iterator = rawLine.index(after: iterator)
        }

        guard iterator < rawLine.endIndex, bullets.contains(rawLine[iterator]) else { return nil }
        iterator = rawLine.index(after: iterator)

        guard iterator < rawLine.endIndex, rawLine[iterator].isWhitespace else { return nil }
        while iterator < rawLine.endIndex, rawLine[iterator].isWhitespace {
            iterator = rawLine.index(after: iterator)
        }

        let text = String(rawLine[iterator...]).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        return MarkdownBulletItem(indent: indent / 2, text: text)
    }

    private func parseTaskItem(from line: String) -> MarkdownTaskItem? {
        let bullets: Set<Character> = ["-", "*", "+"]
        var iterator = line.startIndex

        guard iterator < line.endIndex, bullets.contains(line[iterator]) else { return nil }
        iterator = line.index(after: iterator)

        guard iterator < line.endIndex, line[iterator].isWhitespace else { return nil }
        while iterator < line.endIndex, line[iterator].isWhitespace {
            iterator = line.index(after: iterator)
        }

        guard iterator < line.endIndex, line[iterator] == "[" else { return nil }
        iterator = line.index(after: iterator)

        guard iterator < line.endIndex else { return nil }
        let marker = line[iterator]
        let isChecked: Bool
        switch marker {
        case " ": isChecked = false
        case "x", "X": isChecked = true
        default: return nil
        }
        iterator = line.index(after: iterator)

        guard iterator < line.endIndex, line[iterator] == "]" else { return nil }
        iterator = line.index(after: iterator)

        let text = String(line[iterator...]).trimmingCharacters(in: .whitespaces)
        return MarkdownTaskItem(isChecked: isChecked, text: text)
    }

    private func parseHeading(from line: String) -> MarkdownHeading? {
        guard line.hasPrefix("#") else { return nil }

        var level = 0
        var iterator = line.startIndex
        while iterator < line.endIndex, line[iterator] == "#", level < 7 {
            level += 1
            iterator = line.index(after: iterator)
        }

        guard (1...6).contains(level),
              iterator < line.endIndex,
              line[iterator].isWhitespace
        else { return nil }

        let text = String(line[iterator...]).trimmingCharacters(in: .whitespaces)
        return MarkdownHeading(level: level, text: text)
    }

    private func parseCodeFenceLanguage(from line: String) -> String? {
        let language = line
            .dropFirst(3)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return language.isEmpty ? nil : language
    }

    private func horizontalRuleStyle(_ line: String) -> DividerStyle? {
        guard line.count >= 3 else { return nil }

        let characters = line.filter { !$0.isWhitespace }
        guard let firstCharacter = characters.first, ["-", "*", "_"].contains(firstCharacter) else {
            return nil
        }
        guard characters.count >= 3, characters.allSatisfy({ $0 == firstCharacter }) else {
            return nil
        }

        switch firstCharacter {
        case "*": return .thick
        case "_": return .medium
        default: return .thin
        }
    }

    private func isTableRow(_ line: String) -> Bool {
        line.contains("|") && parseTableCells(line).count > 1
    }

    private func isTableSeparator(_ line: String) -> Bool {
        let cells = parseTableCells(line)
        guard cells.count > 1 else { return false }

        return cells.allSatisfy { cell in
            let trimmedCell = cell.trimmingCharacters(in: .whitespaces)
            let markers = trimmedCell.filter { $0 != ":" }
            return !trimmedCell.isEmpty && markers.allSatisfy { $0 == "-" }
        }
    }

    private func parseTableCells(_ line: String) -> [String] {
        var trimmedLine = line.trimmingCharacters(in: .whitespaces)

        if trimmedLine.hasPrefix("|") {
            trimmedLine.removeFirst()
        }

        if trimmedLine.hasSuffix("|") {
            trimmedLine.removeLast()
        }

        return trimmedLine
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Formatted printing

    private func printDocument() {
        let name = selectedFileName.isEmpty ? "Markdown" : selectedFileName
        printHTMLDocument(makePrintHTML(), jobName: name)
    }

    /// Builds a self-contained HTML document that mirrors the preview layout so
    /// the printed output keeps headings, lists, tables, code blocks and colours.
    private func makePrintHTML() -> String {
        let body = markdownBlocks.map { htmlForBlock($0) }.joined(separator: "\n")
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(printCSS())</style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    private func htmlForBlock(_ block: MarkdownBlock) -> String {
        switch block.content {
        case .text(let text):
            let lines = text.components(separatedBy: "\n").map { inlineHTML($0) }
            return "<p>" + lines.joined(separator: "<br>") + "</p>"
        case .heading(let heading):
            let level = min(max(heading.level, 1), 6)
            return "<h\(level)>\(inlineHTML(heading.text))</h\(level)>"
        case .code(let codeBlock):
            let language = codeBlock.language?.uppercased() ?? ""
            let languageTag = language.isEmpty ? "" : "<div class=\"code-lang\">\(htmlEscape(language))</div>"
            return "<div class=\"code-wrap\">\(languageTag)<pre><code>\(htmlEscape(codeBlock.code))</code></pre></div>"
        case .divider:
            return "<hr>"
        case .table(let table):
            return htmlForTable(table, id: block.id)
        case .taskList(let items):
            let rows = items.map { item -> String in
                let box = item.isChecked ? "&#9745;" : "&#9744;"
                let itemClass = item.isChecked ? " class=\"done\"" : ""
                return "<li\(itemClass)><span class=\"task-box\">\(box)</span> \(inlineHTML(item.text))</li>"
            }.joined()
            return "<ul class=\"tasks\">\(rows)</ul>"
        case .bulletList(let items):
            let rows = items.map { item in
                "<li style=\"margin-left:\(item.indent * 20)px\">\(inlineHTML(item.text))</li>"
            }.joined()
            return "<ul class=\"bullet\">\(rows)</ul>"
        case .orderedList(let items):
            let rows = items.map { item in
                "<li style=\"margin-left:\(item.indent * 20)px\"><span class=\"num\">\(item.number).</span> \(inlineHTML(item.text))</li>"
            }.joined()
            return "<ul class=\"ordered\">\(rows)</ul>"
        case .blockQuote(let quote):
            let lines = quote.components(separatedBy: "\n").map { inlineHTML($0) }
            return "<blockquote>" + lines.joined(separator: "<br>") + "</blockquote>"
        case .image(let image):
            let alt = image.altText.isEmpty ? String(localized: "圖片附件") : image.altText
            return "<div class=\"image-card\"><div class=\"image-title\">\(htmlEscape(alt))</div><div class=\"image-url\">\(htmlEscape(image.urlString))</div></div>"
        }
    }

    private func htmlForTable(_ table: MarkdownTable, id: Int) -> String {
        let count = table.columnCount
        let cleared = tableColorsDisabled.contains(id)
        let tint = tableColor.rgb
        // Match the on-screen grid: cleared tables use a darker border, coloured
        // tables use the faint default from the stylesheet.
        let cellExtra = cleared ? "border-color: #4d4d4d;" : ""

        func headerStyle() -> String {
            if cleared { return "" }
            if let tint {
                return "background-color: rgba(\(tint.r),\(tint.g),\(tint.b),0.75);"
            }
            return "background-color: rgba(128,128,128,0.18);"
        }

        func rowStyle(_ index: Int) -> String {
            if cleared { return "" }
            if !tableStripedRows {
                if let tint { return "background-color: rgba(\(tint.r),\(tint.g),\(tint.b),0.14);" }
                return ""
            }
            if let tint {
                let alpha = index % 2 == 0 ? "0.10" : "0.22"
                return "background-color: rgba(\(tint.r),\(tint.g),\(tint.b),\(alpha));"
            }
            return index % 2 == 0 ? "" : "background-color: rgba(128,128,128,0.08);"
        }

        var html = "<table class=\"md-table\"><tr>"
        for column in 0..<count {
            html += "<th style=\"\(cellExtra)\(headerStyle())\">\(inlineHTML(table.header[safe: column] ?? ""))</th>"
        }
        html += "</tr>"
        for (index, tableRow) in table.rows.enumerated() {
            html += "<tr>"
            for column in 0..<count {
                html += "<td style=\"\(cellExtra)\(rowStyle(index))\">\(inlineHTML(tableRow[safe: column] ?? ""))</td>"
            }
            html += "</tr>"
        }
        html += "</table>"
        return html
    }

    private func htmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Converts a single line of inline Markdown to HTML. The text is escaped
    /// first, then the common inline syntaxes are substituted for HTML tags.
    private func inlineHTML(_ text: String) -> String {
        var result = htmlEscape(text)
        result = replacingMatches(in: result, pattern: #"\[([^\]]*)\]\(([^)\s]+)\)"#) { groups in
            "<a href=\"\(groups[2])\">\(groups[1])</a>"
        }
        result = replacingMatches(in: result, pattern: "`([^`]+)`") { groups in "<code>\(groups[1])</code>" }
        result = replacingMatches(in: result, pattern: #"\*\*([^*]+)\*\*"#) { groups in "<strong>\(groups[1])</strong>" }
        result = replacingMatches(in: result, pattern: #"\*([^*]+)\*"#) { groups in "<em>\(groups[1])</em>" }
        result = replacingMatches(in: result, pattern: "~~([^~]+)~~") { groups in "<del>\(groups[1])</del>" }
        result = replacingMatches(in: result, pattern: "==([^=]+)==") { groups in "<mark>\(groups[1])</mark>" }
        result = replacingMatches(in: result, pattern: #"\^([^\s^]+)\^"#) { groups in "<sup>\(groups[1])</sup>" }
        result = replacingMatches(in: result, pattern: #"~([^\s~]+)~"#) { groups in "<sub>\(groups[1])</sub>" }
        return result
    }

    private func replacingMatches(
        in text: String,
        pattern: String,
        transform: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return text }

        var result = ""
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                result += ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            }
            var groups: [String] = []
            for group in 0..<match.numberOfRanges {
                let range = match.range(at: group)
                groups.append(range.location == NSNotFound ? "" : ns.substring(with: range))
            }
            result += transform(groups)
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            result += ns.substring(with: NSRange(location: cursor, length: ns.length - cursor))
        }
        return result
    }

    private func printCSS() -> String {
        let family = fontFamily == .serif
            ? "Georgia, 'Times New Roman', 'Songti TC', serif"
            : "-apple-system, 'PingFang TC', 'Helvetica Neue', Arial, sans-serif"
        let base = Int(textSize)
        let bulletTint = unorderedListColor.rgb
        let orderedTint = orderedListColor.rgb

        func boxBackground(_ tint: (r: Int, g: Int, b: Int)?) -> String {
            guard let tint else { return "transparent" }
            return "rgba(\(tint.r),\(tint.g),\(tint.b),0.10)"
        }
        func boxBorder(_ tint: (r: Int, g: Int, b: Int)?) -> String {
            guard let tint else { return "rgba(0,0,0,0.08)" }
            return "rgba(\(tint.r),\(tint.g),\(tint.b),0.35)"
        }

        return """
        * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        body { font-family: \(family); font-size: \(base)px; line-height: 1.55; color: #1b1b1b; margin: 0; }
        p { margin: 0.6em 0; }
        h1,h2,h3,h4,h5,h6 { font-family: \(family); line-height: 1.25; margin: 0.8em 0 0.4em; }
        h1 { font-size: \(base * 2)px; border-bottom: 1.5px solid rgba(0,0,0,0.25); padding-bottom: 0.15em; }
        h2 { font-size: \(Int(Double(base) * 1.6))px; border-bottom: 1px solid rgba(0,0,0,0.15); padding-bottom: 0.1em; }
        h3 { font-size: \(Int(Double(base) * 1.35))px; }
        h4 { font-size: \(Int(Double(base) * 1.18))px; }
        h5 { font-size: \(Int(Double(base) * 1.05))px; }
        h6 { font-size: \(base)px; color: #666; }
        a { color: #1a66cc; }
        code { font-family: 'SF Mono', Menlo, Consolas, monospace; font-size: 0.92em; background: rgba(0,0,0,0.06); padding: 0.1em 0.3em; border-radius: 4px; }
        mark { background: rgba(255,224,0,0.55); }
        del { color: #c0392b; }
        hr { border: none; border-top: 1px solid rgba(0,0,0,0.25); margin: 1em 0; }
        blockquote { margin: 0.8em 0; padding: 0.4em 1em; border-left: 3px solid rgba(0,0,0,0.3); color: #333; font-style: italic; }
        .code-wrap { background: #14181f; border-radius: 8px; overflow: hidden; margin: 0.8em 0; }
        .code-lang { color: #9fd6ff; font: 600 0.75em 'SF Mono', Menlo, monospace; padding: 6px 12px; background: rgba(255,255,255,0.06); }
        pre { margin: 0; padding: 12px; }
        pre code { display: block; background: none; padding: 0; color: #dbeaff; font-size: 0.88em; line-height: 1.5; white-space: pre-wrap; word-break: break-word; }
        ul.bullet, ul.ordered, ul.tasks { list-style: none; margin: 0.7em 0; padding: 12px 18px; border-radius: 12px; }
        ul.bullet { background: \(boxBackground(bulletTint)); border: 1px solid \(boxBorder(bulletTint)); }
        ul.ordered { background: \(boxBackground(orderedTint)); border: 1px solid \(boxBorder(orderedTint)); }
        ul.bullet li { position: relative; padding-left: 1.1em; margin: 0.25em 0; }
        ul.bullet li::before { content: "\\2022"; position: absolute; left: 0; }
        ul.ordered li { margin: 0.25em 0; }
        ul.ordered .num { font-weight: 600; margin-right: 0.4em; }
        ul.tasks { background: #fefadb; border: 1px solid rgba(0,0,0,0.1); padding-left: 22px; }
        ul.tasks li { margin: 0.3em 0; border-bottom: 0.7px solid rgba(60,100,200,0.35); padding-bottom: 0.3em; }
        ul.tasks li.done { color: #666; text-decoration: line-through; }
        .task-box { margin-right: 0.4em; }
        table.md-table { border-collapse: collapse; margin: 0.9em 0; }
        table.md-table th, table.md-table td { border: 1px solid rgba(0,0,0,0.18); padding: 8px 12px; text-align: left; vertical-align: top; }
        .image-card { border: 1px solid rgba(0,0,0,0.25); border-radius: 10px; padding: 10px 14px; margin: 0.8em 0; }
        .image-title { font-weight: 600; }
        .image-url { font-family: monospace; font-size: 0.8em; color: #666; word-break: break-all; }
        """
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}
