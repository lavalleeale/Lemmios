import Foundation
import SwiftUI

struct CustomTextEditorComponent: View {
    @Binding var text: String
    @State var addLink: ((String, String) -> Void)?
    @State var linkCommunity: ((String) -> Void)?
    @State var linkTitle = ""
    @State var linkText = ""

    var body: some View {
        TextFieldContainer("", text: $text, addLink: $addLink, linkCommunity: $linkCommunity)
            .popupNavigationView(isPresented: Binding(get: {self.linkCommunity != nil}, set: {_ in self.linkCommunity = nil})) {
                CommunitySelectorComponent(placeholder: "Community Name") { name in
                    if name != "" {
                        linkCommunity!(name)
                    }
                    self.linkCommunity = nil
                }
            }
            .alert("Add Link", isPresented: Binding(get: { self.addLink != nil }, set: { _ in self.addLink = nil })) {
                TextField("Link", text: $linkText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.URL)
                TextField("Text", text: $linkTitle)
                Button("Done") {
                    self.addLink!(linkText, linkTitle)
                    self.addLink = nil
                    self.linkText = ""
                    self.linkTitle = ""
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}

struct TextFieldContainer: UIViewRepresentable {
    private var placeholder: String
    private var text: Binding<String>
    private var addLink: Binding<((String, String) -> Void)?>
    private var linkCommunity: Binding<((String) -> Void)?>

    init(_ placeholder: String, text: Binding<String>, addLink: Binding<((String, String) -> Void)?>, linkCommunity: Binding<((String) -> Void)?>) {
        self.placeholder = placeholder
        self.text = text
        self.addLink = addLink
        self.linkCommunity = linkCommunity
    }

    func makeCoordinator() -> TextFieldContainer.Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<TextFieldContainer>) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.delegate = context.coordinator
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        let communityButton = UIBarButtonItem(title: "Link to community", image: UIImage(systemName: "person.3.sequence"), primaryAction: UIAction { _ in
            context.coordinator.linkCommunity(textView)
        })
        let doneButton = UIBarButtonItem(title: "Add Link", image: UIImage(systemName: "link"), primaryAction: UIAction { _ in
            context.coordinator.addLink(textView)
        })
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [space, doneButton, communityButton, space]

        textView.inputAccessoryView = toolBar

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<TextFieldContainer>) {
        uiView.text = self.text.wrappedValue
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextFieldContainer

        init(_ textFieldContainer: TextFieldContainer) {
            self.parent = textFieldContainer
        }

        @objc func addLink(_ textView: UITextView) {
            self.parent.addLink.wrappedValue = { link, text in
                var link = link
                if let url = URLComponents(string: link) {
                    if url.scheme == nil || url.scheme == "" {
                        link = "https://\(link)"
                    }
                }
                textView.insertText("[\(text)](\(link))")
            }
        }
        
        @objc func linkCommunity(_ textView: UITextView) {
            self.parent.linkCommunity.wrappedValue = { name in
                textView.insertText("!\(name)")
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text.wrappedValue = textView.text ?? ""
        }
    }
}
