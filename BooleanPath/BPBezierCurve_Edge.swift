//
//  BPBezierCurve_Edge.swift
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

private func BPFindEdge1TangentCurves(_ edge: BPBezierCurve, intersection: BPBezierIntersection) -> (leftCurve: BPBezierCurve, rightCurve: BPBezierCurve) {
    
    var leftCurve: BPBezierCurve, rightCurve: BPBezierCurve
    if intersection.isAtStartOfCurve1 {
        leftCurve = edge.previousNonpoint
        rightCurve = edge
    } else if intersection.isAtStopOfCurve1 {
        leftCurve = edge
        rightCurve = edge.nextNonpoint
    } else {
        leftCurve = intersection.curve1LeftBezier
        rightCurve = intersection.curve1RightBezier
    }
    return (leftCurve: leftCurve, rightCurve: rightCurve)
}

private func BPFindEdge2TangentCurves(_ edge: BPBezierCurve, intersection: BPBezierIntersection) -> (leftCurve: BPBezierCurve, rightCurve: BPBezierCurve) {
    
    var leftCurve: BPBezierCurve, rightCurve: BPBezierCurve
    
    if intersection.isAtStartOfCurve2 {
        leftCurve = edge.previousNonpoint
        rightCurve = edge
    } else if intersection.isAtStopOfCurve2 {
        leftCurve = edge
        rightCurve = edge.nextNonpoint
    } else {
        leftCurve = intersection.curve2LeftBezier
        rightCurve = intersection.curve2RightBezier
    }
    
    return (leftCurve: leftCurve, rightCurve: rightCurve)
}

private func BPComputeEdgeTangents(_ leftCurve: BPBezierCurve, rightCurve: BPBezierCurve, offset: Double, edgeTangents: inout BPTangentPair) {
    edgeTangents.left = leftCurve.tangentFromRightOffset(offset)
    edgeTangents.right = rightCurve.tangentFromLeftOffset(offset)
}

private func BPComputeEdge1RangeTangentCurves(_ edge: BPBezierCurve, intersectRange: BPBezierIntersectRange) -> (leftCurve: BPBezierCurve, rightCurve: BPBezierCurve) {
    
    var leftCurve: BPBezierCurve, rightCurve: BPBezierCurve
    if intersectRange.isAtStartOfCurve1 {
        leftCurve = edge.previousNonpoint
    } else {
        leftCurve = intersectRange.curve1LeftBezier
    }
    if intersectRange.isAtStopOfCurve1 {
        rightCurve = edge.nextNonpoint
    } else {
        rightCurve = intersectRange.curve1RightBezier
    }
    return (leftCurve: leftCurve, rightCurve: rightCurve)
}

private func BPComputeEdge2RangeTangentCurves(_ edge: BPBezierCurve, intersectRange: BPBezierIntersectRange) -> (leftCurve: BPBezierCurve, rightCurve: BPBezierCurve) {
    
    var leftCurve: BPBezierCurve, rightCurve: BPBezierCurve
    
    if intersectRange.isAtStartOfCurve2 {
        leftCurve = edge.previousNonpoint
    } else {
        leftCurve = intersectRange.curve2LeftBezier
    }
    if intersectRange.isAtStopOfCurve2 {
        rightCurve = edge.nextNonpoint
    } else {
        rightCurve = intersectRange.curve2RightBezier
    }
    return (leftCurve: leftCurve, rightCurve: rightCurve)
}

extension BPBezierCurve {

    func addCrossing(_ crossing: BPEdgeCrossing) {
        crossing.edge = self
        crossings.append(crossing)
        sortCrossings()
    }
    
    func removeCrossing(_ crossing: BPEdgeCrossing) {
        for (index, element) in crossings.enumerated() {
            if element === crossing {
                crossings.remove(at: index)
                break
            }
        }
        sortCrossings()
    }
    
    func removeAllCrossings() {
        crossings.removeAll()
    }

    var next: BPBezierCurve {
        var nxt: BPBezierCurve = self
        
        if let contour = contour {
            if contour.edges.count > 0 {
                let nextIndex = index + 1
                if nextIndex >= contour.edges.count {
                    nxt = contour.edges.first!
                } else {
                    nxt = contour.edges[nextIndex]
                }
            }
        }
        return nxt
    }
    
    var previous: BPBezierCurve {
        var prev: BPBezierCurve = self
        
        if let contour = contour {
            if contour.edges.count > 0 {
                if index == 0 {
                    prev = contour.edges.last!
                } else {
                    prev = contour.edges[index - 1]
                }
            }
        }
        return prev
    }
    
    var nextNonpoint: BPBezierCurve {
        var edge = self.next
        while edge.isPoint {
            edge = edge.next
        }
        return edge
    }

    var previousNonpoint: BPBezierCurve {
        var edge = self.previous
        while edge.isPoint {
            edge = edge.previous
        }
        return edge
    }

    var hasCrossings: Bool {
        return !crossings.isEmpty
    }

    func crossingsWithBlock(_ block: (_ crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool)) {
        for crossing in crossings {
            let (set, val) = block(crossing)
            if set && val {
                break
            }
        }
    }
    
    func crossingsCopyWithBlock(_ block: (_ crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool)) {
        let crossingsCopy = crossings
        for crossing in crossingsCopy {
            let (set, val) = block(crossing)
            if set && val {
                break
            }
        }
    }

    func nextCrossing(_ crossing: BPEdgeCrossing) -> BPEdgeCrossing? {
        if crossing.index < crossings.count - 1 {
            return crossings[crossing.index + 1]
        } else {
            return nil
        }
    }
    
    func previousCrossing(_ crossing: BPEdgeCrossing) -> BPEdgeCrossing? {
        if crossing.index > 0 {
            return crossings[crossing.index - 1]
        } else {
            return nil
        }
    }
    
    func intersectingEdgesWithBlock(_ block: (_ intersectingEdge: BPBezierCurve) -> Void) {
        
        crossingsWithBlock() {
            (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
            if !crossing.isSelfCrossing {
                if let crossingCounterpartEdge = crossing.counterpart?.edge {
                    block(crossingCounterpartEdge)
                }
            }
            return (false, false)
        }
    }
    
    func selfIntersectingEdgesWithBlock(_ block: (_ intersectingEdge: BPBezierCurve) -> Void) {
        crossingsWithBlock() {
            (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
            
            if crossing.isSelfCrossing {
                if let crossingCounterpartEdge = crossing.counterpart?.edge {
                    block(crossingCounterpartEdge)
                }
            }
            return (false, false)
        }
    }
    
    var firstCrossing: BPEdgeCrossing? {
        return crossings.first
    }
    
    var lastCrossing: BPEdgeCrossing? {
        return crossings.last
    }
    
    var firstNonselfCrossing: BPEdgeCrossing? {
        var first = firstCrossing
        while first != nil && first!.isSelfCrossing {
            first = first?.next
        }
        return first
    }
    
    var lastNonselfCrossing: BPEdgeCrossing? {
        var last = lastCrossing
        while last != nil && last!.isSelfCrossing {
            last = last?.previous
        }
        return last
    }
    
    var hasNonselfCrossings: Bool {
        for crossing in crossings {
            if !crossing.isSelfCrossing {
                return true
            }
        }
        return false
    }
    
    func crossesEdge(_ edge2: BPBezierCurve, atIntersection intersection: BPBezierIntersection) -> Bool {
        if intersection.isTangent {
            return false
        }

        if !intersection.isAtEndPointOfCurve {
            return true
        }
        
        var edge1Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
        var edge2Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
        var offset = 0.0
        
        let (edge1LeftCurve, edge1RightCurve) = BPFindEdge1TangentCurves(self, intersection: intersection)
        let edge1Length = min(edge1LeftCurve.length(), edge1RightCurve.length())
        
        let (edge2LeftCurve, edge2RightCurve) = BPFindEdge2TangentCurves(edge2, intersection: intersection)
        let edge2Length = min(edge2LeftCurve.length(), edge2RightCurve.length())
        
        let maxOffset = min(edge1Length, edge2Length)
        
        repeat {
            BPComputeEdgeTangents(edge1LeftCurve, rightCurve: edge1RightCurve, offset: offset, edgeTangents: &edge1Tangents)
            BPComputeEdgeTangents(edge2LeftCurve, rightCurve: edge2RightCurve, offset: offset, edgeTangents: &edge2Tangents)
            
            offset += 1.0
        } while BPAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset
        
        return BPTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents)
    }

    func crossesEdge(_ edge2: BPBezierCurve, atIntersectRange intersectRange: BPBezierIntersectRange) -> Bool {
       
        var edge1Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
        var edge2Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
        var offset = 0.0
        
        let (edge1LeftCurve, edge1RightCurve) = BPComputeEdge1RangeTangentCurves(self, intersectRange: intersectRange)
        
        let edge1Length = min(edge1LeftCurve.length(), edge1RightCurve.length())
        
        let (edge2LeftCurve, edge2RightCurve) = BPComputeEdge2RangeTangentCurves(edge2, intersectRange: intersectRange)
        let edge2Length = min(edge2LeftCurve.length(), edge2RightCurve.length())
        
        let maxOffset = min(edge1Length, edge2Length);
        
        repeat {
            BPComputeEdgeTangents(edge1LeftCurve, rightCurve: edge1RightCurve, offset: offset, edgeTangents: &edge1Tangents)
            BPComputeEdgeTangents(edge2LeftCurve, rightCurve: edge2RightCurve, offset: offset, edgeTangents: &edge2Tangents)
            
            offset += 1.0
        } while BPAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset
        
        return BPTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents);
    }
    
    // ===============================
    // MARK: Private funcs
    // ===============================
    
    fileprivate func sortCrossings() {
        crossings.sort(by: { $0.order < $1.order })
        for (index, crossing) in crossings.enumerated() {
            crossing.index = index
        }
    }
    
}
