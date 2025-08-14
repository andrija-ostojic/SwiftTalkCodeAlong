protocol StateProperty {
    var value: Any { get nonmutating set }
}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<Box<Value>>

    var wrappedValue: Value {
        get { box.value.value }
        nonmutating set { box.value.value = newValue }
    }

    init(wrappedValue: Value) {
        self.box = Box(Box(wrappedValue))
    }

    var value: Any {
        get { box.value }
        nonmutating set { box.value = newValue as! Box<Value> }
    }
}

final class Box<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}
