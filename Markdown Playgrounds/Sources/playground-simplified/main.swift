import CommonMark
import Ccmark
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // First instance becomes the shared document controller
        _ = MarkdownDocumentController()
    }
}

class MarkdownDocumentController: NSDocumentController {
    override var documentClassNames: [String] {
        return ["MarkdownDocument"]
    }
    
    override var defaultType: String? {
        return "MarkdownDocument"
    }
    
    override func documentClass(forType typeName: String) -> AnyClass? {
        return MarkdownDocument.self
    }
}

struct MarkdownError: Error { }

@objc(MarkdownDocument)
class MarkdownDocument: NSDocument {
    let contentViewController = ViewController()
    
    override class var readableTypes: [String] {
        return ["public.text"]
    }
    
    override class func isNativeType(_ name: String) -> Bool {
        return true
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        guard let str = String(data: data, encoding: .utf8) else {
            throw MarkdownError()
        }
        contentViewController.editor.string = str
    }
    
    override func data(ofType typeName: String) throws -> Data {
        contentViewController.editor.breakUndoCoalescing()
        return contentViewController.editor.string.data(using: .utf8)!
    }
    
    override func makeWindowControllers() {
        let window = NSWindow(contentViewController: contentViewController)
        window.setContentSize(NSSize(width: 800, height: 600))
        let wc = NSWindowController(window: window)
        wc.contentViewController = contentViewController
        addWindowController(wc)
        window.setFrameAutosaveName("windowFrame")
        window.makeKeyAndOrderFront(nil)
    }
}

final class ViewController: NSViewController {
    let editor = NSTextView()
    let output = NSTextView()

    var observerToken: Any?

    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 30, height: 10))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 10, height: 10))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        output.string = "output"
        editor.allowsUndo = true
        
        self.view = splitView([editorSV, outputSV])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observerToken = NotificationCenter.default.addObserver(forName: NSTextView.didChangeNotification, object: editor, queue: nil, using: { [unowned self] _ in
            self.parse()
        })
    }

    func parse() {
        editor.textStorage?.highlightMarkdown()
    }
}

extension String {

    var lineOffsets: [String.Index] {
        var result = [startIndex]
        for index in indices {
            if self[index] == "\n" {
                result.append(self.index(after: index))
            }
        }
        return result
    }
}

extension NSMutableAttributedString {

    func highlightMarkdown() {
        guard let node = Node(markdown: string) else { return }
        let lineOffsets = string.lineOffsets

        func index(of pos: Position) -> String.Index {
            let lineStart = lineOffsets[Int(pos.line - 1)]
            return string.index(lineStart, offsetBy: Int(pos.column - 1))
        }

        let defaultAttributes = Attributes(family: "Helvetica", size: 16)
        setAttributes(defaultAttributes.atts, range: NSRange(location: 0, length: length))

        for c in node.children {
            let start = index(of: c.start)
            let end = index(of: c.end)
            let nsRange = NSRange(start...end, in: string)

            switch c.type {
            case CMARK_NODE_HEADING:
                addAttribute(.foregroundColor, value: NSColor.red, range: nsRange)
            case CMARK_NODE_BLOCK_QUOTE:
                addAttribute(.foregroundColor, value: NSColor.green, range: nsRange)
            case CMARK_NODE_CODE_BLOCK:
                var copy = defaultAttributes
                copy.family = "Monaco"
                addAttribute(.font, value: copy.font, range: nsRange)
            default:
                break
            }
        }
    }
}

let delegate = AppDelegate()
let app = application(delegate: delegate)
app.run()
