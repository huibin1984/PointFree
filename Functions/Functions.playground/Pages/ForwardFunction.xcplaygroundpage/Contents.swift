import Foundation

precedencegroup ForwardApplication {
    associativity: left
}

precedencegroup EffectiveComposition {
    associativity: left
    higherThan: ForwardApplication
}

precedencegroup ForwardComposition {
    associativity: left
    higherThan: ForwardApplication, EffectiveComposition
}

precedencegroup SingleTypeComposition {
    associativity: left
    higherThan: ForwardApplication, EffectiveComposition
}

infix operator |>: ForwardApplication
func |> <A, B>(a: A, f: (A) -> B) -> B {
    f(a)
}
func |> <A>(a: inout A, f: (inout A) -> Void) -> Void {
    f(&a)
}

infix operator >>>: ForwardComposition
func >>> <A, B, C>(f: @escaping  (A) -> B, g: @escaping  (B) -> C) -> (A) -> C {
    {  g(f($0)) }
}

infix operator >=>: EffectiveComposition
func >=> <A, B, C>(f: @escaping (A) -> (B, [String]), g: @escaping (B) -> (C, [String])) -> (A) -> (C, [String]) {
    { a in
        let (b, logs) = f(a)
        let (c, moreLogs) = g(b)
        return (c, logs + moreLogs)
    }
}

func >=> <A, B, C>(f: @escaping (A) -> B?, g: @escaping (B) -> C?) -> ((A) -> C?) {
    { a in
        if let b = f(a) {
            return g(b)
        } else {
            return nil
        }
    }
}

func >=> <A, B, C>(f: @escaping (A) -> [B], g: @escaping (B) -> [C]) -> ((A) -> [C]) {
    { a in
        var r: [C] = []
        for b in f(a) {
            r += g(b)
        }
        return r
    }
}

//func >=> <A, B, C>(
//  _ f: @escaping (A) -> Promise<B>,
//  _ g: @escaping (B) -> Promise<C>
//  ) -> ((A) -> Promise<C>) {
//
//  return { a in
//    fatalError() // an exercise for the viewer
//  }
//}

infix operator <>: SingleTypeComposition
func <> <A>(f: @escaping (A) -> A, g: @escaping (A) -> A) -> ((A) -> A) {
    return f >>> g
}

func <> <A>(f: @escaping (inout A) -> Void, g: @escaping (inout A) -> Void) -> ((inout A) -> Void) {
    return { a in
        f(&a)
        g(&a)
    }
}

square >>> incr >>> String.init

[1, 2, 3, 4]
    .map(incr >>> square >>> String.init)

func compute(_ x: Int) -> Int {
    return x * x + 1
}

func computeWithEffect(_ x: Int) -> Int {
    let computation = x * x + 1
    print("Computed \(computation)")
    return computation
}
//computeWithEffect(2)
//assertEqual(5, computeWithEffect(2))

//[2, 10].map(compute).map(compute)
//[2, 10].map(compute >>> compute)
//
//[2, 10].map(computeWithEffect).map(computeWithEffect)
//__
//[2, 10].map(computeWithEffect >>> computeWithEffect)

func computeAndPrint(_ x: Int) -> (Int, [String]) {
    let computation = x * x + 1
    return (computation, ["Computed \(computation)"])
}

assertEqual(
    (5, ["Computed 5"]),
    computeAndPrint(2)
)
assertEqual(
    (5, ["Computed 3"]),
    computeAndPrint(2)
)
let (computation, logs) = computeAndPrint(2)
logs.forEach { print($0) }

func compose<A, B, C>(
    _ f: @escaping (A) -> (B, [String]),
    _ g: @escaping (B) -> (C, [String])
) -> (A) -> (C, [String]) {
    
    return { a in
        let (b, logs) = f(a)
        let (c, moreLogs) = g(b)
        return (c, logs + moreLogs)
    }
}

2 |> compose(computeAndPrint, computeAndPrint)

2
|> computeAndPrint
>=> incr >>> computeAndPrint
>=> square >>> computeAndPrint

//String.init(utf8String:) >=> URL.init(string:)

func greetWithEffect(_ name: String) -> String {
    let seconds = Int(Date().timeIntervalSince1970) % 60
    return "Hello \(name)! It's \(seconds) seconds past the minute."
}

greetWithEffect("Blob")
// "Hello Blob! It's 14 seconds past the minute."


assertEqual(
    "Hello Blob! It's 32 seconds past the minute.",
    greetWithEffect("Blob")
)

func greet(at date: Date = Date(), name: String) -> String {
    let seconds = Int(date.timeIntervalSince1970) % 60
    return "Hello \(name)! It's \(seconds) seconds past the minute."
}

greet(at: Date(), name: "Blob")


assertEqual(
    "Hello Blob! It's 39 seconds past the minute.",
    greet(at: Date(timeIntervalSince1970: 39), name: "Blob")
)

func greet(at date: Date = Date()) -> (String) -> String {
    return { name in
        return "Hello \(name)! It's \(Int(date.timeIntervalSince1970) % 60) seconds past the minute."
    }
}

func uppercased(_ string: String) -> String {
    return string.uppercased()
}

uppercased >>> greet(at: Date())
greet() >>> uppercased

var formatter = NumberFormatter()

func decimalStyle(_ format: NumberFormatter) {
    format.numberStyle = .decimal
    format.maximumFractionDigits = 2
}

func currencyStyle(_ format: NumberFormatter) {
    format.numberStyle = .currency
    format.roundingMode = .down
}

func wholeStyle(_ format: NumberFormatter) {
    format.maximumFractionDigits = 0
}

decimalStyle(formatter)
wholeStyle(formatter)
formatter.string(for: 1234.6) // "1,235"

currencyStyle(formatter)
formatter.string(for: 1234.6) // "$1,234"

decimalStyle(formatter)
wholeStyle(formatter)
formatter.string(for: 1234.6) // "1,234"

struct NumberFormatterConfig {
    var numberStyle: NumberFormatter.Style = .none
    var roundingMode: NumberFormatter.RoundingMode = .up
    var maximumFractionDigits: Int = 0
    
    var formatter: NumberFormatter {
        let result = NumberFormatter()
        result.numberStyle = self.numberStyle
        result.roundingMode = self.roundingMode
        result.maximumFractionDigits = self.maximumFractionDigits
        return result
    }
}

func decimalStyle(_ format: NumberFormatterConfig) -> NumberFormatterConfig {
    var format = format
    format.numberStyle = .decimal
    format.maximumFractionDigits = 2
    return format
}

func currencyStyle(_ format: NumberFormatterConfig) -> NumberFormatterConfig {
    var format = format
    format.numberStyle = .currency
    format.roundingMode = .down
    return format
}

func wholeStyle(_ format: NumberFormatterConfig) -> NumberFormatterConfig {
    var format = format
    format.maximumFractionDigits = 0
    return format
}

func inoutDecimalStyle(_ format: inout NumberFormatterConfig) {
    format.numberStyle = .decimal
    format.maximumFractionDigits = 2
}

func inoutCurrencyStyle(_ format: inout NumberFormatterConfig) {
    format.numberStyle = .currency
    format.roundingMode = .down
}

func inoutWholeStyle(_ format: inout NumberFormatterConfig) {
    format.maximumFractionDigits = 0
}


var config = NumberFormatterConfig()

wholeStyle(decimalStyle(config))
    .formatter
    .string(for: 1234.6)
// "1,235"

currencyStyle(config)
    .formatter
    .string(for: 1234.6)
// "$1,234"

wholeStyle(decimalStyle(config))
    .formatter
    .string(for: 1234.6)
// "1,235"

inoutDecimalStyle(&config)
inoutWholeStyle(&config)
config.formatter.string(from: 1234.6)

func toInout<A>(
    _ f: @escaping (A) -> A
) -> ((inout A) -> Void) {
    
    return { a in
        a = f(a)
    }
}

func fromInout<A>(
    _ f: @escaping (inout A) -> Void
) -> ((A) -> A) {
    
    return { a in
        var copy = a
        f(&copy)
        return copy
    }
}

config |>
decimalStyle <> currencyStyle

config |>
inoutDecimalStyle <> inoutCurrencyStyle
