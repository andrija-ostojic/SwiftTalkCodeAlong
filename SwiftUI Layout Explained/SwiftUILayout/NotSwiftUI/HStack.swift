//
//  HStack.swift
//  SwiftUILayout
//
//  Created by Andrija Ostojic on 17. 8. 2025..
//

import SwiftUI

@propertyWrapper
final class LayoutState<A> {
    var wrappedValue: A

    init(wrappedValue: A) {
        self.wrappedValue = wrappedValue
    }
}

extension Array where Element == CGFloat {

    func average() -> CGFloat? {
        guard !isEmpty else { return nil }
        let factor = 1 / CGFloat(count)
        return map { $0 * factor }.reduce(0, +)
    }
}

struct HStack_: View_, BuiltinView {
    let children: [AnyView_]
    var spacing: CGFloat? = 0
    var alignment: VerticalAlignment_ = .center
    @LayoutState var sizes: [CGSize] = []

    func render(context: RenderingContext, size: CGSize) {
        let stackY = alignment.alignmentID.defaultValue(in: size)
        var currentX: CGFloat = 0
        for idx in children.indices {
            let childSize = sizes[idx]
            let childY = alignment.alignmentID.defaultValue(in: childSize)
            context.saveGState()
            context.translateBy(x: currentX, y: stackY - childY)
            children[idx].render(context: context, size: childSize)
            context.restoreGState()
            currentX += childSize.width
        }
    }

    func size(proposed: ProposedSize) -> CGSize {
        layout(proposed: proposed)
        let width = sizes.reduce(.zero) { $0 + $1.width }
        let height = sizes.reduce(.zero) { max($0, $1.height) }
        return CGSize(width: width, height: height)
    }

    func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        if alignment.builtin { return nil }
        var currentX: CGFloat = 0
        var values: [CGFloat] = []
        for idx in children.indices {
            let childSize = sizes[idx]
            let child = children[idx]
            if let value = child.customAlignment(for: alignment, in: childSize) {
                values.append(value + currentX)
            }
            currentX += childSize.width
        }
        return values.average() ?? nil
    }

    func layout(proposed: ProposedSize) {
        let flexibility: [LayoutInfo] = children.indices.map { idx in
            let child = children[idx]
            let lower = child.size(proposed: ProposedSize(width: 0, height: proposed.height)).width
            let upper = child.size(proposed: ProposedSize(width: .greatestFiniteMagnitude, height: proposed.height)).width
            return LayoutInfo(minWidth: lower, maxWidth: upper, idx: idx, priority: child.layoutPriority)
        }.sorted()

        var groups = flexibility.group(by: \.priority)
        var sizes: [CGSize] = Array(repeating: .zero, count: children.count)
        let allMinWidths: CGFloat = flexibility.map(\.minWidth).reduce(0, +)
        var remainingWidth = proposed.width! - allMinWidths // TODO: force unwrap

        while !groups.isEmpty {
            let group = groups.removeFirst()
            remainingWidth += group.map(\.minWidth).reduce(0, +)
            var remainingIndices = group.map { $0.idx }

            while !remainingIndices.isEmpty {
                let width = remainingWidth / CGFloat(remainingIndices.count)
                let idx = remainingIndices.removeFirst()
                let child = children[idx]
                let size = child.size(proposed: ProposedSize(width: width, height: proposed.height))
                sizes[idx] = size
                remainingWidth -= size.width
                if remainingWidth < 0 { remainingWidth = 0 }
            }
        }
        self.sizes = sizes
    }

    var layoutPriority: Double { 0 }

    var swiftUI: some View {
        HStack(alignment: alignment.swiftUI, spacing: spacing) {
            ForEach(children.indices, id: \.self) { idx in
                children[idx].swiftUI
            }
        }
    }
}

struct LayoutInfo: Comparable {
    var minWidth: CGFloat
    var maxWidth: CGFloat
    var idx: Int
    var priority: Double

    static func < (lhs: LayoutInfo, rhs: LayoutInfo) -> Bool {
        if lhs.priority > rhs.priority { return true }
        if rhs.priority > lhs.priority { return false }
        return lhs.flexibility < rhs.flexibility
    }

    var flexibility: CGFloat {
        maxWidth - minWidth
    }
}

struct AnyView_: View_, BuiltinView {

    let swiftUI: AnyView
    let impl: AnyViewBase

    init<V: View_>(_ view: V) {
        self.swiftUI = AnyView(view.swiftUI)
        self.impl = AnyViewImp(view)
    }

    func render(context: RenderingContext, size: CGSize) {
        impl.render(context: context, size: size)
    }

    func size(proposed: ProposedSize) -> CGSize {
        impl.size(proposed: proposed)
    }

    func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        impl.customAlignment(for: alignment, in: size)
    }

    var layoutPriority: Double { impl.layoutPriority }
}

class AnyViewBase: BuiltinView {
    func render(context: RenderingContext, size: CGSize) {
        fatalError()
    }
    func size(proposed: ProposedSize) -> CGSize {
        fatalError()
    }
    func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        fatalError()
    }
    var layoutPriority: Double { fatalError() }
}

final class AnyViewImp<V: View_>: AnyViewBase {

    let view: V

    init(_ view: V) {
        self.view = view
    }

    override func render(context: RenderingContext, size: CGSize) {
        view._render(context: context, size: size)
    }

    override func size(proposed: ProposedSize) -> CGSize {
        view._size(proposed: proposed)
    }

    override func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        view._customAlignment(for: alignment, in: size)
    }

    override var layoutPriority: Double {
        view._layoutPriority
    }
}
