import Foundation

@propertyWrapper
public struct Default<Provider: DefaultValueProvider>: Decodable {
    public var wrappedValue: Provider.Value

    public init() {
        wrappedValue = Provider.default
    }

    public init(wrappedValue: Provider.Value) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            wrappedValue = Provider.default
        } else {
            wrappedValue = try container.decode(Provider.Value.self)
        }
    }
}

extension Default: Equatable where Provider.Value: Equatable {
    public static func == (lhs: Default, rhs: Default) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

public extension KeyedDecodingContainer {
    func decode<P>(_: Default<P>.Type, forKey key: Key) throws -> Default<P> {
        if let value = try decodeIfPresent(Default<P>.self, forKey: key) {
            return value
        } else {
            return Default()
        }
    }
}

@propertyWrapper
public struct AbsoluteValue<T: Decodable & Comparable & SignedNumeric>: Decodable {
    
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = abs(try container.decode(T.self))
    }
}

import Foundation

public protocol DefaultValueProvider {
    associatedtype Value: Decodable

    static var `default`: Value { get }
}

public enum False: DefaultValueProvider {
    public static let `default` = false
}

public enum Empty<A>: DefaultValueProvider where A: Decodable, A: RangeReplaceableCollection {
    public static var `default`: A { A() }
}

// This is needed for Arrays of custom types
extension Array: DefaultValueProvider where Element: Decodable {
    public typealias Value = [Element]
    public static var `default`: [Element] { [] }
}


//  ------------------------------------------------


struct Foo: Decodable {
    @Default<False> var bar: Bool
    
//    init(wrappedValue: Bool) {
//        self.bar = wrappedValue
//    }
}


Foo().bar
Foo(bar: Default<False>(wrappedValue: true))

let dict1 = ["bar": true]
let dict2: [String: Any] = [:]
let json1 = try! JSONSerialization.data(withJSONObject: dict1, options: [])
let json2 = try! JSONSerialization.data(withJSONObject: dict2, options: [])

let result1 = try! JSONDecoder().decode(Foo.self, from: json1)
let result2 = try! JSONDecoder().decode(Foo.self, from: json2)

print(result1.bar)
print(result2.bar)

//----------WITHOUT PROPERTY WRAPPERS----------

struct Foo2: Decodable {
    var bar: Bool? = false
}

let json3 = try! JSONSerialization.data(withJSONObject: dict1, options: [])
let json4 = try! JSONSerialization.data(withJSONObject: dict2, options: [])

let result3 = try! JSONDecoder().decode(Foo2.self, from: json3)
let result4 = try!
JSONDecoder().decode(Foo2.self, from: json4)

print(result3.bar!)
print(result4.bar)

//------------------Arrays---------------------

struct FooArmy {
    @Default<Empty> var foos: [Foo]
}

FooArmy().foos



//---------------- ABS ----------------------

struct IndecisiveInt: Decodable {
    @AbsoluteValue var idk: Int
}

let dict3 = ["idk": -9001]
let json5 = try! JSONSerialization.data(withJSONObject: dict3, options: [])
let result5 = try! JSONDecoder().decode(IndecisiveInt.self, from: json5)

print(result5.idk)
