//
//  main.swift
//  game-about-squares
//
//  Created by Harald Bögeholz on 29.08.14.
//  Copyright (c) 2014 Harald Bögeholz. All rights reserved.
//

import Foundation

struct Position : Hashable, Printable
{
    var r, c: Int
    
    var hashValue: Int {
        return r &* 32 &+ c
    }
    var description: String {
        return "(\(r, c))"
    }

    func move (dir : Direction) -> Position
    {
        switch (dir)
            {
        case .Up: return Position(r: r-1, c: c)
        case .Down: return Position(r: r+1, c: c)
        case .Left: return Position(r: r, c: c-1)
        case .Right: return Position(r: r, c: c+1)
        }
    }
}

func == (left: Position, right: Position) -> Bool {
    return (left.r == right.r) && (left.c == right.c)
}

typealias Rectangle = (Position, Position)

enum Color : Printable
{
    case Red, Green, Blue, Black, Yellow, Orange
    var description : String {
        switch self
        {
        case Red: return "Red"
        case Green: return "Green"
        case Blue: return "Blue"
        case Black: return "Black"
        case Yellow: return "Yellow"
        case Orange: return "Orange"
        }
    }
}

enum Direction : Printable
{
    case Up, Down, Left, Right
    var description : String {
        switch self {
        case Up: return "Up"
        case Down: return "Down"
        case Left: return "Left"
        case Right: return "Right"
            }
    }
}

struct Square : Printable
{
    let color : Color
    var direction : Direction

    var description : String
    {
        return "Square(\(color), \(direction))"
    }
    
}

struct State : Printable
{
    var squares : [(Position, Square)]
    
    init(squares: [(Position, Square)])
    {
        self.squares = squares
    }
    
    var description: String {
        var out = "["
        for (p, s) in squares
        {
            out += "\(p):\(s), "
        }
        out += "]"
        return out
    }

    var count : Int {
        return squares.count
    }
    
    func click (squareno : Int, puzzle : Puzzle) -> State
    {
        var newState = self
        push(&newState, squares[squareno].0, squares[squareno].1.direction, puzzle)
        return newState
    }
}


func push(inout state: State, pos: Position, dir: Direction, puzzle: Puzzle)
{
    for i in 0 ..< state.count {
        if state.squares[i].0 == pos {
            let newPos = pos.move(dir)
            push(&state, newPos, dir, puzzle)
            state.squares[i].0 = newPos
            if let newDir = puzzle.arrows[newPos] {
                state.squares[i].1.direction = newDir
            }
            break
        }
    }
}

struct Puzzle
{
    let arrows : [Position : Direction]
    let targets : [Position : Color]
    let initial : State
    let boundingBox : Rectangle
    
    init (arrows : [Position : Direction], targets : [Position : Color], initial : State) {
        func extendBox(inout box : Rectangle, pos : Position)
        {
            box.0.r = min(box.0.r, pos.r)
            box.0.c = min(box.0.c, pos.c)
            box.1.r = max(box.1.r, pos.r)
            box.1.c = max(box.1.c, pos.c)
        }
        self.arrows = arrows
        self.targets = targets
        self.initial = initial
        var box = (Position(r: Int.max, c: Int.max), Position(r: Int.min, c: Int.min))
        for pos in arrows.keys
        {
            extendBox(&box, pos)
        }
        for pos in targets.keys
        {
            extendBox(&box, pos)
        }
        box.0.r -= initial.count
        box.0.c -= initial.count
        box.1.r += initial.count
        box.1.c += initial.count
        self.boundingBox = box
    }
}

let level19 = Puzzle(
    arrows: [
        Position(r: 4, c: 1): .Down,
        Position(r: 5, c: 2): .Down,
        Position(r: 5, c: 4): .Left,
        Position(r: 6, c: 2): .Right,
        Position(r: 6, c: 3): .Up,
        Position(r: 7, c: 1): .Right,
        Position(r: 7, c: 4): .Up
    ],
    targets: [
        Position(r: 1, c: 3): .Red,
        Position(r: 3, c: 3): .Blue,
        Position(r: 5, c: 3): .Black
    ],
    initial: State (squares: [
        (Position(r: 4, c: 1), Square(color: .Red, direction: .Down)),
        (Position(r: 5, c: 2), Square(color: .Blue, direction: .Down)),
        (Position(r: 6, c: 3), Square(color: .Black, direction: .Up))
    ]))

println("Hello, World!")
println(level19.boundingBox)
println(level19.initial)
println(level19.initial.click(0, puzzle: level19))
