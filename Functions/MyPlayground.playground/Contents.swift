import Foundation

precedencegroup ForwardApplication {
    associativity: left
}

precedencegroup ForwardComposition {
    associativity: left
    higherThan: ForwardApplication
}

infix operator |>: ForwardApplication

func |> <A, B>(a: A, f: (A) -> B) -> B {
    f(a)
}

infix operator >>>: ForwardComposition
func >>> <A, B, C>(f: @escaping  (A) -> B, g: @escaping  (B) -> C) -> (A) -> C {
    {  g(f($0)) }
}

func incr(_ x: Int) -> Int {
    return x + 1
}

func square(_ x: Int) -> Int {
    return x * x
}


square >>> incr >>> String.init

[1, 2, 3, 4]
    .map(incr >>> square >>> String.init)
