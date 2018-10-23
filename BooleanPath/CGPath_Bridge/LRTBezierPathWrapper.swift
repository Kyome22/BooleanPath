//
//  LRTBezierPathWrapper.swift
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

public class LRTBezierPathWrapper {
    
    private(set) public var elements: [PathElement]
    fileprivate var _bezierPath: NSBezierPath
    
    var bezierPath: NSBezierPath {
        get {
            return _bezierPath
        }
    }
    
    public init(_ bezierPath:NSBezierPath) {
        elements = []
        _bezierPath = bezierPath
        createElementsFromCGPath()
    }
    
    func createElementsFromCGPath() {
        let cgPath = _bezierPath.cgPath
        cgPath.apply({
            (e : PathElement) -> Void in
            self.elements.append(e)
        })
    }
    
}
