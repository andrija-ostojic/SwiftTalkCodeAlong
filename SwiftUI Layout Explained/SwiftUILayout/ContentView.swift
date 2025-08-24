//
//  ContentView.swift
//  NotSwiftUI
//
//  Created by Chris Eidhof on 05.10.20.
//

import SwiftUI
import Cocoa

func render<V: View_>(view: V, size: CGSize) -> Data {
    return CGContext.pdf(size: size) { context in
        view
            .frame(width: size.width, height: size.height)
            ._render(context: context, size: size)
    }
}

extension View_ {

    var measured: some View_ {
        overlay(GeometryReader_ { size in
            Text_("\(Int(size.width))")
        })
    }
}

enum MyLeading: AlignmentID, SwiftUI.AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        0
    }

    static func defaultValue(in context: CGSize) -> CGFloat {
        0
    }
}
extension HorizontalAlignment_ {
    static let myLeading = HorizontalAlignment_(alignmentID: MyLeading.self, swiftUI: HorizontalAlignment(MyLeading.self))
}

struct ContentView: View {
    let size = CGSize(width: 600, height: 400)

    var sample: some View_ {
        HStack_(children: [
            AnyView_(
                Rectangle_()
                    .foregroundColor(.red)
                    .frame(width: 150, height: 50)
                    .alignmentGuide(for: .myLeading, computeValue: { size in
                        size.width / 2
                    })
                )
            ,
            AnyView_(
                Rectangle_()
                    .foregroundColor(.green)
                    .frame(width: 100)
                    .alignmentGuide(for: .myLeading, computeValue: { size in
                        size.width / 2
                    })
                )
//            ,
//            AnyView_(
//                Rectangle_()
//                    .foregroundColor(.blue)
//                    .frame(width: 100)
//                )
        ])
        .frame(width: 400, height: 200, alignment: Alignment_(horizontal: .myLeading, vertical: .center))
        .border(.white, width: 1)
    }

    @State var opacity: Double = 0.5
    @State var width: CGFloat  = 300
    @State var minWidth: (CGFloat, enabled: Bool) = (100, true)
    @State var maxWidth: (CGFloat, enabled: Bool) = (300, true)

    var body: some View {
        VStack {
            ZStack  {
                Image(nsImage: NSImage(data: render(view: sample, size: size))!)
                    .opacity(1-opacity)
                sample.swiftUI.frame(width: size.width, height: size.height)
                    .opacity(opacity)
            }
            Slider(value: $opacity, in: 0...1)
            HStack  {
                Text("Width \(width.rounded())")
                Slider(value: $width, in: 0...600)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
