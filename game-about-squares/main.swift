//
//  main.swift
//  game-about-squares
//
//  Created by Harald Bögeholz on 29.08.14.
//  Copyright (c) 2014 Harald Bögeholz. All rights reserved.
//

import Foundation

struct Set<T: Hashable>
{
    var dict: [T: Void] = [:]
    var count: Int {
        return dict.count
    }
    
    mutating func insert(elt: T) {
        dict[elt] = ()
    }
    
    func contains(elt: T) -> Bool {
        return dict[elt] != nil
    }
}

struct Position : Hashable, CustomStringConvertible
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

enum Color : CustomStringConvertible
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

enum Direction : CustomStringConvertible
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

struct Square : Hashable, CustomStringConvertible
{
    let color : Color
    var direction : Direction

    var hashValue: Int {
        return color.hashValue &+ direction.hashValue &* 8
    }
    var description : String
    {
        return "Square(\(color), \(direction))"
    }
    
}

func == (s1: Square, s2: Square) -> Bool {
    return s1.color == s2.color && s1.direction == s2.direction
}

/*
func != (s1: Square, s2: Square) -> Bool {
    return !(s1 == s2)
}
*/

struct State : Hashable, CustomStringConvertible
{
    var squares : [(Position, Square)]
    static var nhashes = 0
    
    init(squares: [(Position, Square)])
    {
        self.squares = squares
    }
    
    var hashValue : Int {
        var result = 0
            ++State.nhashes
            for (p, s) in squares {
                result = result &* 0x50000 &+ p.hashValue &+ s.hashValue &* 0x400
            }
            return result
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
    
    subscript (i: Int) -> (Position, Square) {
        get {
            return squares[i]
        }
        set {
            squares[i] = newValue
        }
    }
    
    func click (squareno: Int, puzzle: Puzzle) -> State
    {
        var newState = self
        push(&newState, pos: squares[squareno].0, dir: squares[squareno].1.direction, puzzle: puzzle)
        return newState
    }
    
    func squareAt(pos: Position) -> Square? {
        for (p, s) in squares {
            if p == pos {
                return s
            }
        }
        return nil
    }
}

func == (s1: State, s2: State) -> Bool {
    if s1.count != s2.count {
        return false
    }
    for i in 0 ..< s1.count {
        let (pos1, square1) = s1[i]
        let (pos2, square2) = s2[i]
        if pos1 != pos2 || square1 != square2 {
            return false
        }
    }
    return true
}


func push(inout state: State, pos: Position, dir: Direction, puzzle: Puzzle)
{
    for i in 0 ..< state.count {
        if state[i].0 == pos {
            let newPos = pos.move(dir)
            push(&state, pos: newPos, dir: dir, puzzle: puzzle)
            state[i].0 = newPos
            if let newDir = puzzle.arrows[newPos] {
                state[i].1.direction = newDir
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
    let extendedBoundingBox : Rectangle
    
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
            extendBox(&box, pos: pos)
        }
        for pos in targets.keys
        {
            extendBox(&box, pos: pos)
        }
        self.boundingBox = box
        box.0.r -= initial.count - 1
        box.0.c -= initial.count - 1
        box.1.r += initial.count - 1
        box.1.c += initial.count - 1
        self.extendedBoundingBox = box
    }
    
    func isSolvedBy(state: State) -> Bool {
        for (p, c) in targets {
            if let s = state.squareAt(p) {
                if s.color != c {
                    return false
                }
            }
            else {
                return false
            }
        }
        return true
    }
    
    func inExtendedBoundingBox(state: State) -> Bool {
        for s in state.squares {
            if s.0.r < extendedBoundingBox.0.r || s.0.c < extendedBoundingBox.0.c || s.0.r > extendedBoundingBox.1.r || s.0.c > extendedBoundingBox.1.c {
                return false
            }
        }
        return true
    }
    
    func distanceFromBoundingBox(p: Position) -> Int {
        let d1 = boundingBox.0.r - p.r
        let d2 = boundingBox.0.c - p.c
        let d3 = p.r - boundingBox.1.r
        let d4 = p.c - boundingBox.1.c
        return max(d1, d2, d3, d4)
    }
    
    func solvable(state: State) -> Bool {
        var farsquare = state[0]
        var far_d = distanceFromBoundingBox(farsquare.0)
        for i in 1 ..< state.count {
            let d = distanceFromBoundingBox(state[i].0)
            if d > far_d {
                far_d = d
                farsquare = state[i]
            }
        }
        let (pos, square) = farsquare
        if pos.r < boundingBox.0.r && square.direction != .Down { return false }
        if pos.c < boundingBox.0.c && square.direction != .Right { return false }
        if pos.r > boundingBox.1.r && square.direction != .Up { return false }
        if pos.c > boundingBox.1.c && square.direction != .Left { return false }
        
        return true
    }
}

func solve (puzzle: Puzzle) -> [Color]
{
    var visited = Set<State>()
    var todo: [(State, [Color])] = [(puzzle.initial, [])]
    var n = 0
    
    let startTime = NSDate()
    
    for (var w=0; w < todo.count; ++w)
    {
        let (state, moves) = todo[w]
        for i in 0 ..< state.count {
            let newState = state.click(i, puzzle: puzzle)
            var newMoves = moves
            newMoves.append(state[i].1.color)
            if puzzle.isSolvedBy(newState) {
                let endTime = NSDate()
                let time = endTime.timeIntervalSinceDate(startTime)
                print("Time for solve(): \(time) s")
                return newMoves
            }
            if !visited.contains(newState) {
                visited.insert(newState)
                if puzzle.solvable(newState) {
                    let newPair = (newState, newMoves)
                    todo.append(newPair) // todo.append((newState, newMoves)) // didn't work
                }
            }
            if ++n <= 20 || n % 0x1000 == 0 {
                print("\(newState), \(newMoves.count) moves, \(visited.count) states")
            }
        }
    }
    
    return []
}

func group<T: Equatable> (var list: [T]) -> [(Int, T)]
{
    var out: [(Int, T)] = []
    if list.isEmpty {
        return out
    }
    var prev = list.removeAtIndex(0)
    var count = 1
    for x in list {
        if x != prev {
            let pair = (count, prev)
            out.append(pair)
            prev = x
            count = 0
        }
        ++count
    }
    let pair = (count, prev)
    out.append(pair)
    return out
}

let level0 = Puzzle(
    arrows: [:],
    targets: [Position(r: 3, c: 1): .Red],
    initial: State (squares: [(Position(r: 1, c: 1), Square(color: .Red, direction: .Down))])
)

let level2 = Puzzle(
    arrows: [:],
    targets: [
        Position(r: 1, c: 2): .Blue,
        Position(r: 1, c: 3): .Red,
        Position(r: 2, c: 2): .Black
    ],
    initial: State(squares: [
        (Position(r: 1, c: 1), Square(color: .Red, direction: .Right)),
        (Position(r: 2, c: 4), Square(color: .Black, direction: .Left)),
        (Position(r: 3, c: 2), Square(color: .Blue, direction: .Up))
        ]))

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

let level26 = Puzzle(
    arrows: [
        Position(r: 1, c: 2): .Down,
        Position(r: 2, c: 4): .Left,
        Position(r: 3, c: 1): .Right,
        Position(r: 4, c: 3): .Up
    ],
    targets: [
        Position(r: 1, c: 3): .Orange,
        Position(r: 2, c: 1): .Blue,
        Position(r: 3, c: 4): .Black,
        Position(r: 4, c: 2): .Red
    ],
    initial: State(squares: [
        (Position(r: 1, c: 2), Square(color: .Orange, direction: .Down)),
        (Position(r: 2, c: 4), Square(color: .Black, direction: .Left)),
        (Position(r: 3, c: 1), Square(color: .Blue, direction: .Right)),
        (Position(r: 4, c: 3), Square(color: .Red, direction: .Up))
        ]))
    

print("Solving Game About Squares")

let startTime = NSDate()
let solution = solve(level26)
let endTime = NSDate()

print(group(solution))
print("\(solution.count) moves.")
let time = endTime.timeIntervalSinceDate(startTime)
print("Total Time: \(time) s")
print("Number of hashes: \(State.nhashes)")

