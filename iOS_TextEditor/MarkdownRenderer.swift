//
//  MarkdownRenderer.swift
//  iOS_TextEditor
//
//  Created by Heba Elcc on 26.1.2024.
//
//
import Foundation
import UIKit

class MarkdownRenderer {

    func renderMarkdown(_ markdown: String, textView: UITextView) {
        do {
            let attributedString = try parseMarkdownToAttributedString(markdown)
            textView.attributedText = attributedString
        } catch {
            print("Error rendering Markdown: \(error)")
        }
    }

    private func parseMarkdownToAttributedString(_ markdown: String) throws -> NSAttributedString {
        let parser = MarkdownParser()
        let attributedString = parser.parse(markdown)
        return attributedString
    }
}

class MarkdownParser {
    
    func parse(_ markdown: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: markdown)
        let initialColor = UIColor(hex: "#cacaca")
        attributedString.addAttribute(.foregroundColor, value: initialColor, range: NSRange(location: 0, length: attributedString.length))
               
        // Headers
        applyRegex(pattern: "^(# .*)$", attributedString: attributedString, font: UIFont.boldSystemFont(ofSize: 25))
        applyRegex(pattern: "^(## .*)$", attributedString: attributedString, font: UIFont.boldSystemFont(ofSize: 22))
        applyRegex(pattern: "^(### .*)$", attributedString: attributedString, font: UIFont.boldSystemFont(ofSize: 18))
        applyRegex(pattern: "^(#### .*)$", attributedString: attributedString, font: UIFont.boldSystemFont(ofSize: 16))

        // Emphasis
        applyRegex(pattern: "\\*\\*(.*?)\\*\\*", attributedString: attributedString, font: UIFont.boldSystemFont(ofSize: 14))
        applyRegex(pattern: "\\*(.*?)\\*", attributedString: attributedString, font: UIFont.italicSystemFont(ofSize: 14))
        
        // Underline
        applyRegex(pattern: "__(.*?)__", attributedString: attributedString, font: UIFont.systemFont(ofSize: 14), underline: true)
            
        
        // Lists
        applyRegex(pattern: "(?m)^\\* (.*)$", attributedString: attributedString, font: UIFont.systemFont(ofSize: 14))
        applyRegex(pattern: "(?m)^\\d\\. (.*)$", attributedString: attributedString, font: UIFont.systemFont(ofSize: 14))
        
        return attributedString
    }
    
    private func applyRegex(pattern: String, attributedString: NSMutableAttributedString, font: UIFont? = nil, underline: Bool = false) {
           do {
               let regex = try NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
               let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: attributedString.length))
               
               for match in matches {
                   let nsRange = match.range(at: 1)
                   
                   if underline {
                       attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                   } else if let font = font {
                       attributedString.addAttribute(.font, value: font, range: nsRange)
                   }
               }
           } catch {
               print("Error applying regex: \(error)")
           }
       }
}
