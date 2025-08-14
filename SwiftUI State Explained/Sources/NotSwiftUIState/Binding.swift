//
//  Binding.swift
//  NotSwiftUIState
//
//  Created by Andrija Ostojic on 14. 8. 2025..
//

@propertyWrapper
public struct Binding<T> {
    var get: () -> T
    var set: (T) -> Void

    public var wrappedValue: T {
        get { get() }
        nonmutating set { set(newValue) }
    }
}
