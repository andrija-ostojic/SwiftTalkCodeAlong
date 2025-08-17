//
//  Text.swift
//  SwiftUILayout
//
//  Created by Andrija Ostojic on 16. 8. 2025..
//

import SwiftUI

struct Text_: View_, BuiltinView {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    let font = NSFont.systemFont(ofSize: 16)
    var attributes: [NSAttributedString.Key : Any] {
        [
            .font: font,
            .foregroundColor: NSColor.white
        ]
    }

    var frameSetter: CTFramesetter {
        let str = NSAttributedString(string: text, attributes: attributes)
        return CTFramesetterCreateWithAttributedString(str)
    }

    func render(context: RenderingContext, size: CGSize) {
        let path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(), path, nil)
        context.saveGState()
        CTFrameDraw(frame, context)
        context.restoreGState()
    }

    func size(proposed: ProposedSize) -> CGSize {
        CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRange(), nil, proposed.orMax, nil)
    }

    var swiftUI: some View { Text(text).font(Font(font)) }
}
