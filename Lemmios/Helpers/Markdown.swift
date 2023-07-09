import Foundation

func processMarkdown(input: String, comment: Bool) -> String {
    var output = input.replacingOccurrences(of: "( |^)(/[cm]/|!)([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", with: "[$0](lemmiosapp://$4/c/$3)", options: .regularExpression)
    output = output.replacingOccurrences(of: "( |^)/u/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+.[a-zA-Z]{2,})", with: "[$0](lemmiosapp://$3/u/$2)", options: .regularExpression)
    if (comment) {
        output = output.replacingOccurrences(of: "![", with: "[").replacingOccurrences(of: "[]", with: "[image]")
    }
    return output
}
