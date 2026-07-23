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
    private var jobName: String = ""

    func print(html: String, jobName: String) {
        self.jobName = jobName

        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
        web.navigationDelegate = self
        webView = web
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
        operation.view?.frame = webView.bounds
        operation.run()

        self.webView = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webView = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView = nil
    }
}

#endif
