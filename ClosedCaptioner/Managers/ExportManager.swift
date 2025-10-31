//
//  ExportManager.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Format options for exporting caption text
enum ExportFormat {
    case text
    case pdf
    case html
}

/// Manager that handles exporting caption text to various file formats
class ExportManager {
    /// Shared singleton instance
    static let shared = ExportManager()
    
    private init() {}
    
    /// Exports text to a file in the specified format
    /// - Parameters:
    ///   - text: The text to export
    ///   - format: The export format (text, PDF, or HTML)
    /// - Returns: The URL of the exported file
    /// - Throws: An error if export fails
    func exportText(_ text: String, format: ExportFormat) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "captions_\(Date().timeIntervalSince1970)"
        
        switch format {
        case .text:
            return try exportAsText(text, filename: filename, path: documentsPath)
        case .pdf:
            return try exportAsPDF(text, filename: filename, path: documentsPath)
        case .html:
            return try exportAsHTML(text, filename: filename, path: documentsPath)
        }
    }
    
    /// Exports text as a plain text file
    /// - Parameters:
    ///   - text: The text to export
    ///   - filename: The base filename (without extension)
    ///   - path: The directory path to save the file
    /// - Returns: The URL of the exported file
    /// - Throws: An error if file writing fails
    private func exportAsText(_ text: String, filename: String, path: URL) throws -> URL {
        let fileURL = path.appendingPathComponent("\(filename).txt")
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    /// Exports text as a PDF file
    /// - Parameters:
    ///   - text: The text to export
    ///   - filename: The base filename (without extension)
    ///   - path: The directory path to save the file
    /// - Returns: The URL of the exported file
    /// - Throws: An error if PDF generation fails
    /// - Note: Falls back to text export if UIKit is not available
    private func exportAsPDF(_ text: String, filename: String, path: URL) throws -> URL {
        #if canImport(UIKit)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let fileURL = path.appendingPathComponent("\(filename).pdf")
        
        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16)
            ]
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            attributedText.draw(at: CGPoint(x: 50, y: 50))
        }
        
        return fileURL
        #else
        // Fallback to text export if UIKit not available
        return try exportAsText(text, filename: filename, path: path)
        #endif
    }
    
    /// Exports text as an HTML file
    /// - Parameters:
    ///   - text: The text to export
    ///   - filename: The base filename (without extension)
    ///   - path: The directory path to save the file
    /// - Returns: The URL of the exported file
    /// - Throws: An error if file writing fails
    private func exportAsHTML(_ text: String, filename: String, path: URL) throws -> URL {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Captions</title>
            <style>
                body { font-family: Arial; padding: 20px; }
                .timestamp { color: #888; font-size: 12px; }
            </style>
        </head>
        <body>
            <p>\(text)</p>
        </body>
        </html>
        """
        let fileURL = path.appendingPathComponent("\(filename).html")
        try html.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

