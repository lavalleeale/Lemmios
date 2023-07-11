import Foundation

func processMarkdown(input: String, stripImages: Bool) -> String {
    var output = input.replacingOccurrences(of: "( |^)(/[cm]/|!)([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", with: "[$0](https://$4/c/$3)", options: .regularExpression)
    output = output.replacingOccurrences(of: "( |^)/u/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+.[a-zA-Z]{2,})", with: "[$0](https://$3/u/$2)", options: .regularExpression)
    if (stripImages) {
        output = output.replacingOccurrences(of: "![", with: "[").replacingOccurrences(of: "[]", with: "[image]")
    }
    return output
}
