struct TupleView: BuiltinView, View {
    var children: [AnyBuiltinView]

    init<V1: View, V2: View>(_ v1: V1, _ v2: V2) {
        self.children = [AnyBuiltinView(v1), AnyBuiltinView(v2)]
    }

    func _buildNodeTree(_ node: Node) {
        for index in children.indices {
            if node.children.count <= index  {
                node.children.append(Node())
            }
            children[index]._buildNodeTree(node.children[index])
        }
    }
}
