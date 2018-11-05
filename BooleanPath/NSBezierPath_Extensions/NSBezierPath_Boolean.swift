//
//  NSBezierPath_Boolean.swift
//  Swift BooleanPath for macOS
//
//  Oligin is NSBezierPath+Boolean - Created by Andrew Finnell on 2011/05/31.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Based on VectorBoolean - Created by Leslie Titze on 2015/05/19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//
//  Created by Takuto Nakamura on 2018/10/24.
//  Copyright (c) 2018 Takuto Nakamura. All rights reserved.
//

import Cocoa

public extension NSBezierPath {
    
    func union(_ path: NSBezierPath) -> NSBezierPath {
        let thisGraph = BPBezierGraph(path: self)
        let otherGraph = BPBezierGraph(path: path)
        let result = thisGraph.union(with: otherGraph).bezierPath
        result.copyAttributesFrom(self)
        return result
    }
    
    func intersection(_ path: NSBezierPath) -> NSBezierPath {
        let thisGraph = BPBezierGraph(path: self)
        let otherGraph = BPBezierGraph(path: path)
        let result = thisGraph.intersect(with: otherGraph).bezierPath
        result.copyAttributesFrom(self)
        return result
    }

    func subtraction(_ path: NSBezierPath) -> NSBezierPath {
        let thisGraph = BPBezierGraph(path: self)
        let otherGraph = BPBezierGraph(path: path)
        let result = thisGraph.subtract(with: otherGraph).bezierPath
        result.copyAttributesFrom(self)
        return result
    }
    
    func difference(_ path: NSBezierPath) -> NSBezierPath {
        let thisGraph = BPBezierGraph(path: self)
        let otherGraph = BPBezierGraph(path: path)
        let result = NSBezierPath()
        result.append(thisGraph.subtract(with: otherGraph).bezierPath)
        result.append(otherGraph.subtract(with: thisGraph).bezierPath)
        result.copyAttributesFrom(self)
        return result
    }
    
}
