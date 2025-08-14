import Combine

protocol AnyObservedObject {
    func addDependency(_ node: Node)
}

@propertyWrapper
struct ObservedObject<ObjectType: ObservableObject>: AnyObservedObject {
    private var box: ObservedObjectBox<ObjectType>

    @dynamicMemberLookup
    struct Wrapper {
        var observedObject: ObservedObject

        fileprivate init(_ o: ObservedObject<ObjectType>) {
            observedObject = o
        }

        subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Value>) -> Binding<Value> {
            Binding(
                get: { observedObject.wrappedValue[keyPath: keyPath] },
                set: { observedObject.wrappedValue[keyPath: keyPath] = $0 }
            )
        }
    }

    var wrappedValue: ObjectType {
        box.object
    }

    var projectedValue: Wrapper {
        Wrapper(self)
    }

    func addDependency(_ node: Node) {
        box.addDependency(node)
    }

    init(wrappedValue: ObjectType) {
        self.box = ObservedObjectBox(wrappedValue)
    }
}

extension ObservedObject: Equatable {
    static func == (lhs: ObservedObject, rhs: ObservedObject) -> Bool {
        lhs.wrappedValue === rhs.wrappedValue
    }
}

fileprivate final class ObservedObjectBox<ObjectType: ObservableObject> {
    var object: ObjectType
    var cancellable: AnyCancellable?
    weak var node: Node?

    init(_ object: ObjectType) {
        self.object = object
    }

    func addDependency(_ node: Node) {
        if node === self.node { return }
        self.node = node
        cancellable = object.objectWillChange.sink { _ in
            node.needsRebuild = true
        }
    }
}
