//
//  BPEdgeCrossing.swift
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

class BPEdgeCrossing {
    
    fileprivate var _intersection: BPBezierIntersection
    
    var edge: BPBezierCurve?
    var counterpart: BPEdgeCrossing?
    var fromCrossingOverlap = false
    var entry = false
    var processed = false
    var selfCrossing = false
    var index: Int = 0
    
    init(intersection: BPBezierIntersection) {
        _intersection = intersection
    }
    
    var isProcessed: Bool {
        return processed
    }
    
    var isSelfCrossing: Bool {
        return selfCrossing
    }
    
    var isEntry: Bool {
        return entry
    }
    
    func removeFromEdge() {
        if let edge = edge {
            edge.removeCrossing(self)
        }
    }
    
    var order: Double {
        return parameter
    }
    
    var next: BPEdgeCrossing? {
        if let edge = edge {
            return edge.nextCrossing(self)
        } else {
            return nil
        }
    }
    
    var previous: BPEdgeCrossing? {
        if let edge = edge {
            return edge.previousCrossing(self)
        } else {
            return nil
        }
    }
    
    var nextNonself: BPEdgeCrossing? {
        var nextNon: BPEdgeCrossing? = next
        while nextNon != nil && nextNon!.isSelfCrossing {
            nextNon = nextNon!.next
        }
        return nextNon
    }
    
    var previousNonself: BPEdgeCrossing? {
        var prevNon: BPEdgeCrossing? = previous
        while prevNon != nil && prevNon!.isSelfCrossing {
            prevNon = prevNon!.previous
        }
        return prevNon
    }

    var parameter: Double {
        if edge == _intersection.curve1 {
            return _intersection.parameter1
        } else {
            return _intersection.parameter2
        }
    }

    var location: CGPoint {
        return _intersection.location
    }

    var curve: BPBezierCurve? {
        return edge
    }
    
    var leftCurve: BPBezierCurve? {
        if isAtStart {
            return nil
        }
        if edge == _intersection.curve1 {
            return _intersection.curve1LeftBezier
        } else {
            return _intersection.curve2LeftBezier
        }
    }

    var rightCurve: BPBezierCurve? {
        if isAtEnd {
            return nil
        }
        if edge == _intersection.curve1 {
            return _intersection.curve1RightBezier
        } else {
            return _intersection.curve2RightBezier
        }
    }
    
    var isAtStart: Bool {
        if edge == _intersection.curve1 {
            return _intersection.isAtStartOfCurve1
        } else {
            return _intersection.isAtStartOfCurve2
        }
    }
    
    var isAtEnd: Bool {
        if edge == _intersection.curve1 {
            return _intersection.isAtStopOfCurve1
        } else {
            return _intersection.isAtStopOfCurve2
        }
    }
    
}
