//
//  Binding.swift
//  NotSwiftUIState
//
//  Created by Andrija Ostojic on 14. 8. 2025..
//

import Foundation

@propertyWrapper
public struct Binding<T>: Equatable {

    private let id = UUID()

    public static func == (lhs: Binding<T>, rhs: Binding<T>) -> Bool {
        lhs.id == rhs.id
    }

    var get: () -> T
    var set: (T) -> Void

    public var wrappedValue: T {
        get { get() }
        nonmutating set { set(newValue) }
    }
}
