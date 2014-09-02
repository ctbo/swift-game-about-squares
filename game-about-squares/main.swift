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
        return r &* 65536 &+ c
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

enum Color
{
    case Red, Green, Blue, Black, Yellow, Orange
}

enum Direction
{
    case Up, Down, Left, Right
}

struct Square
{
    let color : Color
    var direction : Direction
}

struct State
{
    let squares : [Position : Square]
    
    init(squares: [Position : Square])
    {
        self.squares = squares
    }

    var count : Int {
        return squares.count
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
        Position(r: 4, c: 1): Square(color: .Red, direction: .Down),
        Position(r: 5, c: 2): Square(color: .Blue, direction: .Down),
        Position(r: 6, c: 3): Square(color: .Black, direction: .Up)
    ]))

println("Hello, World!")
println(level19.boundingBox)

