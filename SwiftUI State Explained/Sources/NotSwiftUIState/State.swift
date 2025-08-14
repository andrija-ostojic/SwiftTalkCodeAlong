protocol StateProperty {
    var value: Any { get nonmutating set }
}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<StateBox<Value>>

    var wrappedValue: Value {
        get { box.value.value }
        nonmutating set { box.value.value = newValue }
    }

    init(wrappedValue: Value) {
        self.box = Box(StateBox(wrappedValue))
    }

    var value: Any {
        get { box.value }
        nonmutating set { box.value = newValue as! StateBox<Value> }
    }

    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}

final class Box<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

var currentGlobalBodyBode: Node? = nil

final class StateBox<Value> {
    private var _value: Value
    private var dependencies: [Weak<Node>] = []

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        get {
            dependencies.append(Weak(currentGlobalBodyBode!))
            // skip duplicates and remove nil entries
            return _value
        }
        set {
            _value = newValue
            for d in dependencies {
                d.value?.needsRebuild = true
            }
        }
    }
}

final class Weak<Value: AnyObject> {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}
