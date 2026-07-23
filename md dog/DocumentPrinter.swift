//
//  DocumentPrinter.swift
//  md dog
//
//  Prints a formatted HTML document. On iOS the system print controller renders
//  the markup directly; on macOS an off-screen web view lays out the HTML and
//  drives the print operation.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import WebKit
#endif

/// Presents the system print UI for the given HTML document.
@MainActor
func printHTMLDocument(_ html: String, jobName: String) {
    #if os(iOS)
    let printInfo = UIPrintInfo.printInfo()
    printInfo.outputType = .general
    printInfo.jobName = jobName

    let controller = UIPrintInteractionController.shared
    controller.printInfo = printInfo

    let formatter = UIMarkupTextPrintFormatter(markupText: html)
    formatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
    controller.printFormatter = formatter

    controller.present(animated: true, completionHandler: nil)
    #elseif os(macOS)
    HTMLPrintCoordinator.shared.print(html: html, jobName: jobName)
    #endif
}

#if os(macOS)

/// Loads HTML into an off-screen `WKWebView` and runs a print operation once the
/// content has finished laying out. The coordinator retains the web view for the
/// duration of the print so it is not deallocated mid-operation.
@MainActor
private final class HTMLPrintCoordinator: NSObject, WKNavigationDelegate {
    static let shared = HTMLPrintCoordinator()

    private var webView: WKWebView?
    private var hostWindow: NSWindow?
    private var jobName: String = ""

    private static let paperSize = NSRect(x: 0, y: 0, width: 595, height: 842)

    func print(html: String, jobName: String) {
        self.jobName = jobName

        let web = WKWebView(frame: Self.paperSize)
        web.navigationDelegate = self

        // Host the web view in an off-screen window. Without a window the view
        // never lays out, so `printOperation` has nothing to paginate and the
        // print panel never appears.
        let window = NSWindow(
            contentRect: Self.paperSize,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = web
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderBack(nil)

        webView = web
        hostWindow = window
        web.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.topMargin = 36
        info.bottomMargin = 36
        info.leftMargin = 36
        info.rightMargin = 36
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = false

        let operation = webView.printOperation(with: info)
        operation.jobTitle = jobName
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.view?.frame = Self.paperSize

        // Present as a sheet on the app's active window when possible, otherwise
        // fall back to an app-modal print panel.
        if let host = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0 !== hostWindow && $0.isVisible }) {
            operation.runModal(
                for: host,
                delegate: self,
                didRun: #selector(printOperationDidRun(_:success:contextInfo:)),
                contextInfo: nil
            )
        } else {
            operation.run()
            cleanup()
        }
    }

    @objc private func printOperationDidRun(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        cleanup()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cleanup()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        cleanup()
    }

    private func cleanup() {
        hostWindow?.orderOut(nil)
        hostWindow = nil
        webView = nil
    }
}

#endif
