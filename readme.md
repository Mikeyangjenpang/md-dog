# MD Dog

MD Dog is a lightweight Markdown reader app. On launch it loads this `readme.md` as a preview; you can tap "Open File" in the top-right corner to read your own `.md`, `.markdown`, or plain text files.

---

## Features

- Open local Markdown files
- Show file name, line count, and character count
- Switch between "Preview" and "Source" modes
- Selectable and copyable preview content
- Error alert when a file can't be read

## Markdown Element Showcase

This document includes common elements you'll find in Markdown files, used to test the app's rendering.

### Headings

# H1 Heading
## H2 Heading
### H3 Heading
#### H4 Heading
##### H5 Heading
###### H6 Heading

### Paragraphs and Line Breaks

This is a normal paragraph. Markdown treats consecutive text as a single paragraph, which suits notes, specifications, and README documents.

This is another paragraph.  
The line above ends with two spaces plus a newline to force a hard break.

### Text Styles

Plain text, **bold text**, *italic text*, ***bold italic text***, `inline code`.

Some Markdown syntax may render as plain text depending on the parser, e.g. ~~strikethrough~~, ==highlight==, H~2~O, X^2^.

### Blockquote

> This is a quoted passage.
>
> Quotes may include multiple paragraphs and are commonly used for notes, summaries, or excerpts.

### Unordered List

- First item
- Second item
  - Nested item A
  - Nested item B
- Third item

### Ordered List

1. Launch the app
2. Tap "Open File"
3. Choose a Markdown file
4. Toggle between Preview and Source

### Task List

- [x] Read Markdown files
- [x] Support Preview and Source modes
- [ ] Add search
- [ ] Add recent files

### Links

[Apple Developer Documentation](https://developer.apple.com/documentation/)

You can also show URLs inline: https://developer.apple.com

### Image Syntax

![Markdown image alt text](https://example.com/image.png)

MD Dog currently renders Markdown using system text; image syntax shows the alt text and does not fetch remote resources.

### Horizontal Rules

Above and below are horizontal rule syntaxes.

---

***

___

### Code Blocks

```swift
import SwiftUI

struct MarkdownExampleView: View {
    let title = "MD Dog"

    var body: some View {
        Text("Hello, Markdown")
            .font(.headline)
    }
}
```

```json
{
  "name": "MD Dog",
  "type": "markdown-reader",
  "lightweight": true
}
```

### Tables

| Element | Description | Status |
| --- | --- | --- |
| Heading | H1 to H6 | Parsed |
| List | Ordered, unordered, nested | Parsed |
| Code | Inline and block | Parsed |
| Table | Common GFM syntax | Rendered |

### Escape Characters

To show Markdown reserved characters, use a backslash: \*not italic\*, \# not a heading, \`not code\`.

### HTML Snippets

<strong>HTML bold</strong>

Markdown files sometimes mix in HTML. MD Dog previews rely on the system Markdown parser; unsupported HTML is preserved as text.

### Footnote Syntax

Here is a footnote reference.[^note]

[^note]: This is the footnote content. Support for footnotes varies between Markdown parsers.

## Usage Tips

- Small notes, READMEs, and how-to documents are ideal for reading directly in MD Dog.
- If you run into an extended Markdown syntax that isn't supported, switch to "Source" to see the complete content.
- This app focuses on fast reading and never modifies the original file.

---

# MD Dog（中文）

MD Dog 是一個輕量化 Markdown 檔案讀取 app。啟動時會先載入這份 `readme.md` 作為預覽，你也可以點右上角的「開啟檔案」讀取自己的 `.md`、`.markdown` 或純文字檔案。

---

## 功能

- 開啟本機 Markdown 檔案
- 顯示檔名、行數與字元數
- 在「預覽」和「原文」之間切換
- 預覽內容可選取複製
- 讀取失敗時顯示錯誤提示

## Markdown 元素展示

這份文件包含常見 Markdown 檔案會出現的元素,用來測試目前 app 的呈現效果。

### 標題

# H1 標題
## H2 標題
### H3 標題
#### H4 標題
##### H5 標題
###### H6 標題

### 段落與換行

這是一個普通段落。Markdown 會把連續文字視為同一段,適合用來撰寫說明、筆記、規格文件和 README。

這是另一個段落。  
這一行前面使用兩個空白加換行,表示硬換行。

### 文字樣式

一般文字、**粗體文字**、*斜體文字*、***粗斜體文字***、`行內程式碼`。

部分 Markdown 語法可能依系統解析器呈現為普通文字,例如 ~~刪除線~~、==標記文字==、H~2~O、X^2^。

### 引用

> 這是一段引用文字。
>
> 引用可以包含多個段落,也常用於筆記、摘要或文件摘錄。

### 無序清單

- 第一個項目
- 第二個項目
  - 巢狀項目 A
  - 巢狀項目 B
- 第三個項目

### 有序清單

1. 開啟 app
2. 點選「開啟檔案」
3. 選擇 Markdown 檔案
4. 切換預覽或原文模式

### 任務清單

- [x] 支援讀取 Markdown 檔案
- [x] 支援預覽和原文模式
- [ ] 加入搜尋功能
- [ ] 加入最近開啟檔案

### 連結

[Apple Developer Documentation](https://developer.apple.com/documentation/)

也可以直接顯示網址:https://developer.apple.com

### 圖片語法

![Markdown 圖片替代文字](https://example.com/image.png)

目前 MD Dog 使用系統文字渲染 Markdown,圖片語法會以文字內容為主,不會下載遠端圖片。

### 分隔線

上方與下方都是水平分隔線語法。

---

***

___

### 程式碼區塊

```swift
import SwiftUI

struct MarkdownExampleView: View {
    let title = "MD Dog"

    var body: some View {
        Text("Hello, Markdown")
            .font(.headline)
    }
}
```

```json
{
  "name": "MD Dog",
  "type": "markdown-reader",
  "lightweight": true
}
```

### 表格

| 元素 | 說明 | 狀態 |
| --- | --- | --- |
| 標題 | H1 到 H6 | 支援解析 |
| 清單 | 有序、無序、巢狀 | 支援解析 |
| 程式碼 | 行內與區塊 | 支援解析 |
| 表格 | GFM 常見語法 | 支援表格呈現 |

### 跳脫字元

如果要顯示 Markdown 保留字元,可以使用反斜線:\*不是斜體\*、\# 不是標題、\`不是程式碼\`。

### HTML 片段

<strong>HTML 粗體</strong>

Markdown 文件有時會混用 HTML。MD Dog 的預覽以系統 Markdown 解析結果為準,若無法解析會保留為文字。

### 註腳語法

這裡有一個註腳參考。[^note-zh]

[^note-zh]: 這是註腳內容。不同 Markdown 解析器對註腳支援程度不同。

## 使用建議

- 小型筆記、README、操作說明適合直接用 MD Dog 閱讀。
- 若遇到系統不支援的擴充 Markdown 語法,可以切到「原文」查看完整內容。
- 本 app 專注於快速讀取,不會修改原始檔案。
