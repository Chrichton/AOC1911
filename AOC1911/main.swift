//
//  main.swift
//  AOC1911
//
//  Created by Heiko Goes on 21.12.19.
//  Copyright © 2019 Heiko Goes. All rights reserved.
//

enum Opcode: Int {
    case Add = 1
    case Multiply = 2
    case Halt = 99
    case Input = 3
    case Output = 4
    case JumpIfTrue = 5
    case JumpIfFalse = 6
    case LessThan = 7
    case Equals = 8
    case AdjustRelativeBase = 9
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

struct ParameterModes {
    let digits: String
    private var parameterPointer: Int
    
    init(digits: String) {
        self.digits = digits
        parameterPointer = digits.count - 1
    }
    
    mutating func getNext() -> ParameterMode {
        let digit = parameterPointer >= 0 ? digits[parameterPointer...parameterPointer] : "0"
        parameterPointer -= 1
        
        return ParameterMode(rawValue: Int(digit)!)!
    }
}

enum ParameterMode: Int {
    case Position = 0
    case Immediate = 1
    case Relative = 2
}

struct Point: Hashable {
    let x: Int
    let y: Int
}

enum Direction {
    case north
    case west
    case east
    case south
}

struct Program {
    private(set) var memory: [Int]
    private var instructionPointer = 0
    private var input: Int
    private var relativeBase = 0
    
    private var actualPoint: Point
    private(set) var visitedPoints = Dictionary<Point,Int>()
    private var firstOutput = true
    private var actualDirection: Direction = .north
    
    public mutating func getNextParameter(parameterMode: ParameterMode) -> Int {
        var parameter: Int
        switch parameterMode {
            case .Position:
                parameter = memory[memory[instructionPointer]]
            case .Immediate:
                parameter = memory[instructionPointer]
            case .Relative:
                parameter = memory[memory[instructionPointer] + relativeBase]
        }
        
        instructionPointer += 1
        return parameter
    }
    
    public mutating func run() {
        repeat {
            var startString = String(memory[instructionPointer])
            if startString.count == 1 {
                startString = "0" + startString
            }
            
            instructionPointer += 1
            
            let opcode = Opcode(rawValue: Int(startString[startString.count - 2...startString.count - 1])!)!
            if opcode == .Halt {
                break
            }
            
            var parameterModes = startString.count >= 3 ? ParameterModes(digits: startString[0...startString.count - 3]) : ParameterModes(digits: "")
            
            switch opcode {
                case .Add:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = parameter1 + parameter2
                    } else {
                        memory[parameter3] = parameter1 + parameter2
                    }
                case .Multiply:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = parameter1 * parameter2
                    } else {
                        memory[parameter3] = parameter1 * parameter2
                    }
                case .Halt: ()
                case .Input:
                    let parameter = getNextParameter(parameterMode: .Immediate)
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter + relativeBase] = input
                    } else {
                        memory[parameter] = input
                    }
                case .Output:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    if firstOutput {
                        visitedPoints[actualPoint] = parameter1
                        firstOutput = false
                    } else {
                        if parameter1 == 0 { // left 90°
                            switch actualDirection {
                            case .north:
                                actualPoint = Point(x: actualPoint.x - 1, y: actualPoint.y)
                            case .south:
                                actualPoint = Point(x: actualPoint.x + 1, y: actualPoint.y)
                            case .west:
                                actualPoint = Point(x: actualPoint.x, y: actualPoint.y - 1)
                            case.east:
                                actualPoint = Point(x: actualPoint.x, y: actualPoint.y + 1)
                            }
                        } else { // right 90°
                            switch actualDirection {
                            case .north:
                                actualPoint = Point(x: actualPoint.x + 1, y: actualPoint.y)
                            case .south:
                                actualPoint = Point(x: actualPoint.x - 1, y: actualPoint.y)
                            case .west:
                                actualPoint = Point(x: actualPoint.x, y: actualPoint.y + 1)
                            case.east:
                                actualPoint = Point(x: actualPoint.x, y: actualPoint.y - 1)
                            }
                        }

                        input = visitedPoints[actualPoint] ?? 0
                        firstOutput = true
                    }
                    print(parameter1)
                case .JumpIfTrue:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    if parameter1 != 0 {
                        let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                        instructionPointer = parameter2
                    } else {
                        instructionPointer += 1
                    }
                case .JumpIfFalse:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    if parameter1 == 0 {
                        let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                        instructionPointer = parameter2
                    } else {
                        instructionPointer += 1
                    }
                case .LessThan:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    let value = parameter1 < parameter2 ? 1 : 0
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = value
                    } else {
                        memory[parameter3] = value
                    }
                case .Equals:
                   let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                   let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                   let parameter3 = getNextParameter(parameterMode: .Immediate)
                   
                   let parameterMode = parameterModes.getNext()
                   let value = parameter1 == parameter2 ? 1 : 0
                   if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = value
                   } else {
                        memory[parameter3] = value
                    }
                case .AdjustRelativeBase:
                   let parameter = getNextParameter(parameterMode: parameterModes.getNext())
                   relativeBase += parameter
            }
        } while true
    }
    
    init(memory: String, input: Int) {
        self.memory = memory
            .split(separator: ",")
            .map{ Int($0)! }
        self.input = input
        actualPoint = Point(x: 0,y: 0)
    }
}

//let memoryString = """
//109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99
//"""
let memoryString = """
3,8,1005,8,351,1106,0,11,0,0,0,104,1,104,0,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,102,1,8,28,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,0,10,4,10,1002,8,1,51,1006,0,85,2,1109,8,10,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,0,10,4,10,102,1,8,80,1,2,2,10,1,1007,19,10,1,1001,13,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,1,8,10,4,10,1001,8,0,113,1,2,1,10,1,1109,17,10,1,108,20,10,2,1005,3,10,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,1002,8,1,151,2,5,19,10,1,104,19,10,1,109,3,10,1006,0,78,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,0,10,4,10,1002,8,1,189,1006,0,3,2,1004,1,10,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,1,10,4,10,1001,8,0,218,1,1008,6,10,1,104,8,10,1006,0,13,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,0,10,4,10,102,1,8,251,1006,0,17,1006,0,34,1006,0,24,1006,0,4,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,285,1006,0,25,2,1103,11,10,1006,0,75,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,1,8,10,4,10,101,0,8,316,2,1002,6,10,1006,0,30,2,106,11,10,1006,0,21,101,1,9,9,1007,9,1072,10,1005,10,15,99,109,673,104,0,104,1,21101,0,937151009684,1,21101,0,368,0,1105,1,472,21102,386979963796,1,1,21102,379,1,0,1106,0,472,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,21101,179410325723,0,1,21101,426,0,0,1106,0,472,21101,0,179355823195,1,21102,437,1,0,1106,0,472,3,10,104,0,104,0,3,10,104,0,104,0,21101,0,825460785920,1,21101,460,0,0,1105,1,472,21102,1,838429614848,1,21102,1,471,0,1105,1,472,99,109,2,21202,-1,1,1,21102,40,1,2,21102,1,503,3,21101,493,0,0,1105,1,536,109,-2,2106,0,0,0,1,0,0,1,109,2,3,10,204,-1,1001,498,499,514,4,0,1001,498,1,498,108,4,498,10,1006,10,530,1101,0,0,498,109,-2,2106,0,0,0,109,4,2101,0,-1,535,1207,-3,0,10,1006,10,553,21101,0,0,-3,21202,-3,1,1,22101,0,-2,2,21101,0,1,3,21101,572,0,0,1105,1,577,109,-4,2105,1,0,109,5,1207,-3,1,10,1006,10,600,2207,-4,-2,10,1006,10,600,21202,-4,1,-4,1106,0,668,21202,-4,1,1,21201,-3,-1,2,21202,-2,2,3,21102,619,1,0,1105,1,577,22102,1,1,-4,21101,0,1,-1,2207,-4,-2,10,1006,10,638,21101,0,0,-1,22202,-2,-1,-2,2107,0,-3,10,1006,10,660,22101,0,-1,1,21101,660,0,0,106,0,535,21202,-2,-1,-2,22201,-4,-2,-4,109,-5,2105,1,0
"""
    + String(repeating: ",0", count: 10000)

var program = Program(memory: memoryString, input: 0)

program.run()

print(program.visitedPoints.count)
