//
//  ViewController.swift
//  iOS_TextEditor
//
//  Created by Heba Elcc on 23.1.2024.
//

import UIKit

class ViewController: UIViewController {
    var isUserTyping = false
    var typingStartTime: Date?
    var isFormattingByToolbar = false
    var isBulletPointActive = false
    var debounceTimer: Timer?
    var existingAttributedString: NSAttributedString?
    var renderedText: NSMutableAttributedString = NSMutableAttributedString()
    var originalMarkdownText = ""
    var userFormattedTexts: [NSMutableAttributedString] = []
    var isFormattingAction = false
    let markdownRenderer = MarkdownRenderer()
    
    
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var wordCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolBar()
        textView.delegate = self
        textView.textColor = .white
        textView.allowsEditingTextAttributes = true
        
        
        updateWordCount()
        updateTime()
        
        if isFormattingAction == false{
            updateTextViewWithMarkdown()
        }
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Keyboard Handling
    
    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            textView.contentInset = contentInsets
            textView.scrollIndicatorInsets = contentInsets
            
            var aRect = view.frame
            aRect.size.height -= keyboardSize.height
            if !aRect.contains(textView.frame.origin) {
                textView.scrollRectToVisible(textView.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    // MARK: - Set up a toolbar with buttons for formatting options
    
    fileprivate func setupToolBar() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        toolBar.backgroundColor =  .clear
        toolBar.tintColor = .white
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let toolBarSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let photoButton = UIBarButtonItem(customView: createButton(withImage: "photo.fill", action: #selector(photoImportButtonPressed)))
        let formattingButton = UIBarButtonItem(image: UIImage(systemName: "textformat"), style: .plain, target: self, action: #selector(showFormattingOptions))
        navigationItem.rightBarButtonItem = formattingButton
        
        let boldButton = UIBarButtonItem(customView: createButton(withImage: "bold", action: #selector(boldButtonPressed)))
        let italicButton = UIBarButtonItem(customView: createButton(withImage: "italic", action: #selector(italicButtonPressed)))
        let underlineButton = UIBarButtonItem(customView: createButton(withImage: "underline", action: #selector(underlineButtonPressed)))
        let orderedListButton = UIBarButtonItem(customView: createButton(withImage: "list.bullet", action: #selector(toggleBulletPointsButtonPressed)))
        let unorderedListButton = UIBarButtonItem(customView: createButton(withImage: "list.number", action: #selector(updateNumberedText)))
        
        toolBar.items = [photoButton, flexibleSpace, formattingButton, flexibleSpace, boldButton, flexibleSpace, italicButton, flexibleSpace, underlineButton, flexibleSpace, orderedListButton, flexibleSpace, unorderedListButton]
        
        toolBar.sizeToFit()
        toolBar.isUserInteractionEnabled = true
        textView.inputAccessoryView = toolBar
    }
    
    func createButton(withImage imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let systemImage = UIImage(systemName: imageName)
        
        button.setImage(systemImage, for: .normal)
        button.setImage(systemImage?.withTintColor(.systemGray, renderingMode: .alwaysOriginal), for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: action, for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        return button
    }
}

//MARK: - Actions
extension ViewController{
    
    @objc func photoImportButtonPressed() {
        isFormattingAction = true
        let alertController = UIAlertController(title: "Import a photo", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.showImagePicker(sourceType: .camera)
        }
        let cameraRollAction = UIAlertAction(title: "Camera Roll", style: .default) { _ in
            self.showImagePicker(sourceType: .photoLibrary)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel , handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(cameraRollAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true , completion: nil)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        
        present(imagePicker , animated: true , completion:  nil)
    }
    
    @objc func showFormattingOptions(){
        isFormattingAction = true
        let alertController = UIAlertController(title: "Formatting Options", message: nil, preferredStyle: .actionSheet)
        
        let heading1Action = UIAlertAction(title: "Heading 1", style: .default) { _ in
            self.applyStyleToSelectedText(.heading1)
        }
        let heading2Action = UIAlertAction(title: "Heading 2", style: .default) { _ in
            self.applyStyleToSelectedText(.heading2)
        }
        let heading3Action = UIAlertAction(title: "Heading 3", style: .default) { _ in
            self.applyStyleToSelectedText(.heading3)
        }
        let normalTextAction = UIAlertAction(title: "Normal Text", style: .default) { _ in
            self.applyStyleToSelectedText(.normalText)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(heading1Action)
        alertController.addAction(heading2Action)
        alertController.addAction(heading3Action)
        alertController.addAction(normalTextAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true , completion: nil)
    }
    
    @objc func underlineButtonPressed() {
        isFormattingAction = true
        
        let currentUnderlineStyle = textView.typingAttributes[.underlineStyle] as? NSNumber
        let isUnderlined = currentUnderlineStyle?.intValue == NSUnderlineStyle.single.rawValue
        
        let newUnderlineStyle: NSUnderlineStyle = isUnderlined ? [] : .single
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: newUnderlineStyle.rawValue]
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let attributedText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
            attributedText.addAttributes(underlineAttribute, range: selectedRange)
            textView.attributedText = attributedText
        } else {
            textView.typingAttributes[.underlineStyle] = newUnderlineStyle.rawValue
        }
        
    }
    
    @objc func boldButtonPressed() {
        isFormattingAction = true
        
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 14.0)
        let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.traitBold)
        
        let newFont: UIFont
        
        if isBold {
            newFont = UIFont.systemFont(ofSize: 14.0)
        } else {
            newFont = UIFont.boldSystemFont(ofSize: 14.0)
        }
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let attributedText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
            attributedText.addAttribute(.font, value: newFont, range: selectedRange)
            textView.attributedText = attributedText
        } else {
            textView.typingAttributes[.font] = newFont
        }
    }
    
    @objc func italicButtonPressed() {
        isFormattingAction = true
        
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 14.0)
        let isItalic = currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic)
        
        let newFont: UIFont
        
        if isItalic {
            newFont = UIFont.systemFont(ofSize: 14.0)
        } else {
            newFont = UIFont.italicSystemFont(ofSize: 14.0)
        }
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let attributedText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
            attributedText.addAttribute(.font, value: newFont, range: selectedRange)
            textView.attributedText = attributedText
        } else {
            textView.typingAttributes[.font] = newFont
        }
        
        
    }
    
    @objc func toggleBulletPointsButtonPressed() {
        isFormattingAction = true
        
        guard let selectedRange = textView.selectedTextRange else {
            return
        }
        guard let selectedText = textView.text(in: selectedRange) else {
            return
        }
        
        let lines = selectedText.components(separatedBy: CharacterSet.newlines)
        let bulletList = lines.map { "• \($0)" }
        let formattedText = bulletList.joined(separator: "\n")
        
        textView.replace(selectedRange, withText: formattedText)
        
        if let currentLineRange = textView.selectedTextRange,
           let nextLineStart = textView.position(from: currentLineRange.end, offset: 1),
           let nextLineRange = textView.textRange(from: nextLineStart, to: textView.endOfDocument),
           let nextLineText = textView.text(in: nextLineRange) {
            if nextLineText.trimmingCharacters(in: .whitespaces) == "" {
                textView.replace(nextLineRange, withText: "• ")
            }
        }
    }
    
    @objc func updateNumberedText() {
        isFormattingAction = true
        
        applyNumberedListFormatting()
        
    }
    
    func generateNumberedList(items: [String]) -> String {
        var markdown = ""
        
        for (index, item) in items.enumerated() {
            let leadingSpaces = item.prefix(while: { $0 == " " })
            let level = leadingSpaces.count / 4 + 1
            let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
            markdown += "\(String(repeating: "    ", count: level - 1))\(index + 1). \(trimmedItem)\n"
        }
        
        return markdown
    }
    
    func applyNumberedListFormatting() {
        guard let selectedRange = textView.selectedTextRange else {
            return
        }
        
        guard let selectedText = textView.text(in: selectedRange) else {
            return
        }
        
        let lines = selectedText.components(separatedBy: CharacterSet.newlines)
        let numberedMarkdown = generateNumberedList(items: lines)
        
        textView.replace(selectedRange, withText: numberedMarkdown)
    }
}
// MARK: - UITextViewDelegate Methods
extension ViewController: UITextViewDelegate {
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    func textViewShouldReturn(textView: UITextView!) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.insertText("\n")
            
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateWordCount()
        if isFormattingAction == false{
            updateTextViewWithMarkdown()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isUserTyping {
            isUserTyping = true
            typingStartTime = Date()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if isUserTyping {
            isUserTyping = false
            typingStartTime = nil
        }
    }
    
    
    
    
    //MARK: - Word Counter
    private func updateWordCount(){
        let words = textView.text.split {$0.isWhitespace || $0.isNewline}
        let wordCount = words.count
        wordCountLabel.text = "•\(wordCount) words"
    }
    @objc func updateTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if isUserTyping, let startTime = typingStartTime {
            timeLabel.text = "\(formatter.string(from: startTime))"
        } else {
            timeLabel.text = "\(formatter.string(from: Date()))"
        }
    }
}

//MARK: - Image Picker
extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let imageSize = CGSize(width: 200, height: 200)
            let resizedImage = selectedImage.resize(targetSize: imageSize)
            let attachment = NSTextAttachment()
            attachment.image = resizedImage
            let imageString = NSAttributedString(attachment: attachment)
            textView.textStorage.insert(imageString, at: textView.selectedRange.location)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - TextStyle

extension ViewController {
    
    enum TextStyle {
        case heading1, heading2, heading3, normalText
    }
    
    func applyStyleToSelectedText(_ style: TextStyle) {
        var attributes: [NSAttributedString.Key: Any] = [:]
        isFormattingAction = true
        
        switch style {
        case .heading1:
            attributes[.font] = UIFont.boldSystemFont(ofSize: 25.0)
        case .heading2:
            attributes[.font] = UIFont.boldSystemFont(ofSize: 22.0)
        case .heading3:
            attributes[.font] = UIFont.boldSystemFont(ofSize: 18.0)
        case .normalText:
            attributes[.font] = UIFont.systemFont(ofSize: 16.0)
        }
        attributes[.foregroundColor] = UIColor(hex: "#cacaca")
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            textView.textStorage.addAttributes(attributes, range: selectedRange)
        } else {
            let location = textView.selectedRange.location
            textView.typingAttributes = attributes
            textView.selectedRange = NSMakeRange(location, 0)
        }
    }
}


extension NSAttributedString.Key {
    static let toolbarGenerated = NSAttributedString.Key(rawValue: "ToolbarGeneratedAttribute")
}
//MARK: - Markdown Rendering
extension ViewController {
    func updateTextViewWithMarkdown() {
        let markdownText = textView.text ?? ""
        markdownRenderer.renderMarkdown(markdownText, textView: textView)
    }
}
