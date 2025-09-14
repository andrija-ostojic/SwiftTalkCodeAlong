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
    var codeBlocks: [CodeBlock] = []
    var observerToken: Any?
    var repl: REPL!

    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 30, height: 10))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 10, height: 10))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        editor.allowsUndo = true
        
        self.view = splitView([editorSV, outputSV])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        repl = REPL(
            onStdOut: { [unowned output] in
                output.textStorage?.append(NSAttributedString(string: $0))
            }, onStdErr: { [unowned output] in
                output.textStorage?.append(NSAttributedString(string: $0))
            })
        observerToken = NotificationCenter.default.addObserver(forName: NSTextView.didChangeNotification, object: editor, queue: nil, using: { [unowned self] _ in
            self.parse()
        })
    }

    func parse() {
        guard let attributedString = editor.textStorage else { return }
        codeBlocks = attributedString.highlightMarkdown()
    }

    @objc func execute() {
        let pos = editor.selectedRange().location
        guard let block = codeBlocks.first(where: { $0.range.contains(pos) }) else { return }
        repl.execute(block.text)
    }
}

final class REPL {
    private let process = Process()
    private let stdIn = Pipe()
    private let stdOut = Pipe()
    private let stdErr = Pipe()

    private var stdOutToken: Any?
    private var stdErrToken: Any?

    init(onStdOut: @escaping (String) -> (), onStdErr: @escaping (String) -> ()) {
        process.launchPath = "/usr/bin/swift"
        process.standardInput = stdIn.fileHandleForReading
        process.standardOutput = stdOut.fileHandleForWriting
        process.standardError = stdOut.fileHandleForWriting

        stdOutToken = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdOut.fileHandleForReading, queue: nil) { [unowned self] note in
            let data = self.stdOut.fileHandleForReading.availableData
            let string = String(data: data, encoding: .utf8)!
            onStdOut(string)
            self.stdOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }

        stdErrToken = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdOut.fileHandleForReading, queue: nil) { [unowned self] note in
            let data = self.stdErr.fileHandleForReading.availableData
            let string = String(data: data, encoding: .utf8)!
            onStdErr(string)
            self.stdErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }

        process.launch()
        stdOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        stdErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    func execute(_ code: String) {
        stdIn.fileHandleForWriting.write(code.data(using: .utf8)!)
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

extension CommonMark.Node {
    /// When visiting a node, you can modify the state, and the modified state gets passed on to all children.
    func visitAll<State>(_ initial: State, _ callback: (Node, inout State) -> ()) {
        for c in children {
            var copy = initial
            callback(c, &copy)
            c.visitAll(copy, callback)
        }
    }
}

let delegate = AppDelegate()
let app = application(delegate: delegate)
app.run()
