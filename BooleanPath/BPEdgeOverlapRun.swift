//
//  BPEdgeOverlapRun.swift
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

class BPEdgeOverlapRun {
    
    var overlaps: [BPEdgeOverlap] = []

    @discardableResult
    func insertOverlap(_ overlap: BPEdgeOverlap) -> Bool {
        if overlaps.count == 0 {
            overlaps.append(overlap)
            return true
        }
        if let lastOverlap = overlaps.last {
            if lastOverlap.fitsBefore(overlap) {
                overlaps.append(overlap)
                return true
            }
        }
        if let firstOverlap = overlaps.first {
            if firstOverlap.fitsAfter(overlap) {
                overlaps.insert(overlap, at: 0)
                return true
            }
        }
        return false
    }
    
    var isComplete: Bool {
        if overlaps.count == 0 {
            return false
        }
        if let lastOverlap = overlaps.last {
            let firstOverlap = overlaps[0]
            return lastOverlap.fitsBefore(firstOverlap)
        }
        return false
    }
    
    func doesContainCrossing(_ crossing: BPEdgeCrossing) -> Bool {
        if let crossingEdge = crossing.edge {
            return doesContainParameter(crossing.parameter, onEdge: crossingEdge)
        } else {
            return false
        }
    }
    
    func doesContainParameter(_ parameter: Double, onEdge edge: BPBezierCurve) -> Bool {
        if overlaps.count == 0 {
            return false
        }
        var containingOverlap: BPEdgeOverlap?
        for overlap in overlaps {
            if overlap.edge1 == edge || overlap.edge2 == edge {
                containingOverlap = overlap
                break
            }
        }

        if let containingOverlap = containingOverlap {
            
            let lastOverlap = overlaps.last
            let firstOverlap = overlaps[0]
            
            let atTheStart = containingOverlap === firstOverlap
            let extendsBeforeStart = !atTheStart || (atTheStart && lastOverlap!.fitsBefore(firstOverlap))
            
            let atTheEnd = containingOverlap === lastOverlap
            let extendsAfterEnd = !atTheEnd || (atTheEnd && firstOverlap.fitsAfter(lastOverlap!))
            
            return containingOverlap.doesContainParameter(parameter, onEdge: edge, startExtends: extendsBeforeStart, endExtends: extendsAfterEnd)
        } else {
            return false
        }
    }
    
    var isCrossing: Bool {
        let firstOverlap = overlaps[0]
        if let lastOverlap = overlaps.last {
            var edge1Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
            var edge2Tangents = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
            
            var offset = 0.0
            var maxOffset = 0.0
            
            repeat {
                let length1 = BPComputeEdge1Tangents(firstOverlap, lastOverlap: lastOverlap, offset: offset, edge1Tangents: &edge1Tangents)
                let length2 = BPComputeEdge2Tangents(firstOverlap, lastOverlap: lastOverlap, offset: offset, edge2Tangents: &edge2Tangents)
                maxOffset = min(length1, length2);
                
                offset += 1.0
            } while ( BPAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset);
            
            if BPTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents) {
                return true
            }
            var testPoints = BPTangentPair(left: CGPoint.zero, right: CGPoint.zero)
            BPComputeEdge1TestPoints(firstOverlap, lastOverlap: lastOverlap, offset: 1.0, testPoints: &testPoints)
            if let contour2 = firstOverlap.edge2.contour {
                let testPoint1Inside = contour2.containsPoint(testPoints.left)
                let testPoint2Inside = contour2.containsPoint(testPoints.right)
                return testPoint1Inside != testPoint2Inside
            }
        }
        return false
    }
    
    func addCrossings() {
        if overlaps.count == 0 {
            return
        }
        
        let middleOverlap = overlaps[overlaps.count / 2]
        middleOverlap.addMiddleCrossing()
    }
    
    var contour1: BPBezierContour? {
        if overlaps.count == 0 {
            return nil
        }
        let overlap = overlaps[0]
        return overlap.edge1.contour
    }
    
    var contour2: BPBezierContour? {
        if overlaps.count == 0 {
            return nil
        }
        let overlap = overlaps[0]
        return overlap.edge2.contour
    }
    
}

// =============================
// MARK: Utility functions
// =============================

func BPComputeEdge1Tangents(_ firstOverlap: BPEdgeOverlap,
                            lastOverlap: BPEdgeOverlap,
                            offset: Double,
                            edge1Tangents: inout BPTangentPair) -> Double {
    
    var firstLength = 0.0
    var lastLength = 0.0
    
    if firstOverlap.range.isAtStartOfCurve1 {
        let otherEdge1 = firstOverlap.edge1.previousNonpoint
        edge1Tangents.left = otherEdge1.tangentFromRightOffset(offset)
        firstLength = otherEdge1.length()
    } else {
        edge1Tangents.left = firstOverlap.range.curve1LeftBezier.tangentFromRightOffset(offset)
        firstLength = firstOverlap.range.curve1LeftBezier.length()
    }
    
    if lastOverlap.range.isAtStopOfCurve1 {
        let otherEdge1 = lastOverlap.edge1.nextNonpoint
        edge1Tangents.right = otherEdge1.tangentFromLeftOffset(offset)
        lastLength = otherEdge1.length()
    } else {
        edge1Tangents.right = lastOverlap.range.curve1RightBezier.tangentFromLeftOffset(offset)
        lastLength = lastOverlap.range.curve1RightBezier.length()
    }
    
    return min(firstLength, lastLength)
}

func BPComputeEdge2Tangents(_ firstOverlap: BPEdgeOverlap,
                            lastOverlap: BPEdgeOverlap,
                            offset: Double,
                            edge2Tangents: inout BPTangentPair) -> Double {
    
    var firstLength = 0.0
    var lastLength = 0.0
    
    if !firstOverlap.range.reversed {
        if firstOverlap.range.isAtStartOfCurve2 {
            let otherEdge2 = firstOverlap.edge2.previousNonpoint
            edge2Tangents.left = otherEdge2.tangentFromRightOffset(offset)
            firstLength = otherEdge2.length()
        } else {
            edge2Tangents.left = firstOverlap.range.curve2LeftBezier.tangentFromRightOffset(offset)
            firstLength = firstOverlap.range.curve2LeftBezier.length()
        }
        
        if lastOverlap.range.isAtStopOfCurve2 {
            let otherEdge2 = lastOverlap.edge2.nextNonpoint
            edge2Tangents.right = otherEdge2.tangentFromLeftOffset(offset)
            lastLength = otherEdge2.length()
        } else {
            edge2Tangents.right = lastOverlap.range.curve2RightBezier.tangentFromLeftOffset(offset)
            lastLength = lastOverlap.range.curve2RightBezier.length()
        }
        
    } else {
        if firstOverlap.range.isAtStopOfCurve2 {
            let otherEdge2 = firstOverlap.edge2.nextNonpoint
            edge2Tangents.left = otherEdge2.tangentFromLeftOffset(offset)
            firstLength = otherEdge2.length()
        } else {
            edge2Tangents.left = firstOverlap.range.curve2RightBezier.tangentFromLeftOffset(offset)
            firstLength = firstOverlap.range.curve2RightBezier.length()
        }
        
        if lastOverlap.range.isAtStartOfCurve2 {
            let otherEdge2 = lastOverlap.edge2.previousNonpoint
            edge2Tangents.right = otherEdge2.tangentFromRightOffset(offset)
            lastLength = otherEdge2.length()
        } else {
            edge2Tangents.right = lastOverlap.range.curve2LeftBezier.tangentFromRightOffset(offset)
            lastLength = lastOverlap.range.curve2LeftBezier.length()
        }
    }
    
    return min(firstLength, lastLength)
}

func BPComputeEdge1TestPoints(_ firstOverlap: BPEdgeOverlap,
                              lastOverlap: BPEdgeOverlap,
                              offset: Double,
                              testPoints: inout BPTangentPair) {
    
    if firstOverlap.range.isAtStartOfCurve1 {
        let otherEdge1 = firstOverlap.edge1.previousNonpoint
        testPoints.left = otherEdge1.pointFromRightOffset(offset)
    } else {
        testPoints.left = firstOverlap.range.curve1LeftBezier.pointFromRightOffset(offset)
    }
    
    if lastOverlap.range.isAtStopOfCurve1 {
        let otherEdge1 = lastOverlap.edge1.nextNonpoint
        testPoints.right = otherEdge1.pointFromLeftOffset(offset)
    } else {
        testPoints.right = lastOverlap.range.curve1RightBezier.pointFromLeftOffset(offset)
    }
}


