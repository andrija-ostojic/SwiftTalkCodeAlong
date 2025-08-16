import SwiftUI

var sample: some View_ {
    Ellipse_()
        .frame(width: 200, height: 100)
        .border(NSColor.blue, width: 2)
        .frame(width: 300, height: 300, alignment: .topLeading)
        .border(NSColor.yellow, width: 2)
}

func render<V: View_>(view: V, size: CGSize) -> Data {
    return CGContext.pdf(size: size) { context in
        view
            .frame(width: size.width, height: size.height)
            ._render(context: context, size: size)
    }
}

struct ContentView: View {
    let size = CGSize(width: 600, height: 400)

    @State var opacity: CGFloat = 0.5

    var body: some View {
        VStack {
            Slider(value: $opacity)
            ZStack {
                Image(nsImage: NSImage(data: render(view: sample, size: size))!)
                    .opacity(1.0 - opacity)
                sample.swiftUI.frame(width: size.width, height: size.height)
                    .opacity(opacity)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
