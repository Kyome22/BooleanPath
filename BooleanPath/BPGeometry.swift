//
//  BPGeometry.swift
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

// ===================================
// MARK: Point Helpers
// ===================================

let isRunningOn64BitDevice = MemoryLayout<Int>.size == MemoryLayout<Int64>.size

var BPPointClosenessThreshold: Double {
    if isRunningOn64BitDevice {
        return 1e-10
    } else {
        return 1e-2
    }
}

var BPTangentClosenessThreshold: Double {
    if isRunningOn64BitDevice {
        return 1e-12
    } else {
        return 1e-2
    }
}

var BPBoundsClosenessThreshold: Double {
    if isRunningOn64BitDevice {
        return 1e-9
    } else {
        return 1e-2
    }
}

func BPDistanceBetweenPoints(_ point1: CGPoint, point2: CGPoint) -> Double {
    let xDelta = Double(point2.x - point1.x)
    let yDelta = Double(point2.y - point1.y)
    
    return sqrt(xDelta * xDelta + yDelta * yDelta);
}

func BPDistancePointToLine(_ point: CGPoint, lineStartPoint: CGPoint, lineEndPoint: CGPoint) -> Double {
    let lineLength = BPDistanceBetweenPoints(lineStartPoint, point2: lineEndPoint)
    if lineLength == 0.0 {
        return 0.0
    }
    
    let xDelta = Double(lineEndPoint.x - lineStartPoint.x)
    let yDelta = Double(lineEndPoint.y - lineStartPoint.y)
    
    let num = Double(point.x - lineStartPoint.x) * xDelta + Double(point.y - lineStartPoint.y) * yDelta
    
    let u = num / (lineLength * lineLength)
    
    let intersectionPoint = CGPoint(x: lineStartPoint.x + CGFloat(u * xDelta),
                                    y: lineStartPoint.y + CGFloat(u * yDelta)
    )
    
    return BPDistanceBetweenPoints(point, point2: intersectionPoint)
}

func BPAddPoint(_ point1: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPoint(x: point1.x + point2.x,
                   y: point1.y + point2.y)
}

func BPUnitScalePoint(_ point: CGPoint, scale: Double) -> CGPoint {
    
    var result = point
    let length = BPPointLength(point)
    if length != 0.0 {
        result.x = CGFloat(Double(result.x) * (scale/length))
        result.y = CGFloat(Double(result.y) * (scale/length))
    }
    return result
}

func BPScalePoint(_ point: CGPoint, scale: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scale,
                   y: point.y * scale)
}

func BPDotMultiplyPoint(_ point1: CGPoint, point2: CGPoint) -> Double {
    let dotX = Double(point1.x) * Double(point2.x)
    let dotY = Double(point1.y) * Double(point2.y)
    return dotX + dotY
}

func BPSubtractPoint(_ point1: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPoint(x: point1.x - point2.x,
                   y: point1.y - point2.y)
}

func BPPointLength(_ point: CGPoint) -> Double {
    let xSq = Double(point.x) * Double(point.x)
    let ySq = Double(point.y) * Double(point.y)
    return sqrt(xSq + ySq)
}

func BPPointSquaredLength(_ point: CGPoint) -> Double {
    let xSq = Double(point.x) * Double(point.x)
    let ySq = Double(point.y) * Double(point.y)
    return xSq + ySq
}

func BPNormalizePoint(_ point: CGPoint) -> CGPoint {
    var result = point
    let length = BPPointLength(point)
    if length != 0.0 {
        result.x = CGFloat(Double(result.x) / length)
        result.y = CGFloat(Double(result.y) / length)
    }
    return result
}

func BPNegatePoint(_ point: CGPoint) -> CGPoint {
    return CGPoint(x: -point.x,
                   y: -point.y)
}

func BPRoundPoint(_ point: CGPoint) -> CGPoint {
    return CGPoint(x: round(point.x),
                   y: round(point.y))
}

func BPLineNormal(_ lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {
    return BPNormalizePoint(CGPoint(x: lineStart.y - lineEnd.y,
                                    y: lineEnd.x - lineStart.x))
}

func BPLineMidpoint(_ lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {
    let distance = BPDistanceBetweenPoints(lineStart, point2: lineEnd)
    let tangent = BPNormalizePoint(BPSubtractPoint(lineEnd, point2: lineStart))
    return BPAddPoint(lineStart, point2: BPUnitScalePoint(tangent, scale: distance / 2.0))
}

func BPRectGetTopLeft(_ rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.minX,
                   y: rect.minY)
}

func BPRectGetTopRight(_ rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.maxX,
                   y: rect.minY)
}

func BPRectGetBottomLeft(_ rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.minX,
                   y: rect.maxY)
}

func BPRectGetBottomRight(_ rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.maxX,
                   y: rect.maxY)
}

func BPExpandBoundsByPoint(_ topLeft: inout CGPoint, bottomRight: inout CGPoint, point: CGPoint) {
    if point.x < topLeft.x { topLeft.x = point.x }
    if point.x > bottomRight.x { bottomRight.x = point.x }
    if point.y < topLeft.y { topLeft.y = point.y }
    if point.y > bottomRight.y { bottomRight.y = point.y }
}

func BPUnionRect(_ rect1: CGRect, rect2: CGRect) -> CGRect {
    var topLeft = BPRectGetTopLeft(rect1)
    var bottomRight = BPRectGetBottomRight(rect1)
    BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: BPRectGetTopLeft(rect2))
    BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: BPRectGetTopRight(rect2))
    BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: BPRectGetBottomRight(rect2))
    BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: BPRectGetBottomLeft(rect2))
    
    return CGRect(x: topLeft.x,
                  y: topLeft.y,
                  width: bottomRight.x - topLeft.x,
                  height: bottomRight.y - topLeft.y)
}

// ===================================
// MARK: -- Distance Helper methods --
// ===================================

func BPArePointsClose(_ point1: CGPoint, point2: CGPoint) -> Bool {
    return BPArePointsCloseWithOptions(point1, point2: point2, threshold: BPPointClosenessThreshold)
}

func BPArePointsCloseWithOptions(_ point1: CGPoint, point2: CGPoint, threshold: Double) -> Bool {
    return BPAreValuesCloseWithOptions(Double(point1.x), value2: Double(point2.x), threshold: threshold) && BPAreValuesCloseWithOptions(Double(point1.y), value2: Double(point2.y), threshold: threshold);
}

func BPAreValuesClose(_ value1: CGFloat, value2: CGFloat) -> Bool {
    return BPAreValuesCloseWithOptions(Double(value1), value2: Double(value2), threshold: BPPointClosenessThreshold)
}

func BPAreValuesClose(_ value1: Double, value2: Double) -> Bool {
    return BPAreValuesCloseWithOptions(value1, value2: value2, threshold: Double(BPPointClosenessThreshold))
}

func BPAreValuesCloseWithOptions(_ value1: Double, value2: Double, threshold: Double) -> Bool {
    let delta = value1 - value2
    return (delta <= threshold) && (delta >= -threshold)
}

// ===================================
// MARK: ---- Angle Helpers ----
// ===================================

//////////////////////////////////////////////////////////////////////////
// Helper methods for angles
//
let Two_π = 2.0 * Double.pi
let π = Double.pi
let Half_π = Double.pi / 2

func NormalizeAngle(_ value: Double) -> Double {
    var value = value
    while value < 0.0 {  value = value + Two_π }
    while value >= Two_π { value = value - Two_π }
    
    return value
}

func PolarAngle(_ point: CGPoint) -> Double {
    var value = 0.0
    let dpx = Double(point.x)
    let dpy = Double(point.y)
    
    if point.x > 0.0 {
        value = atan(dpy / dpx)
    }
    else if point.x < 0.0 {
        if point.y >= 0.0 {
            value = atan(dpy / dpx) + π
        } else {
            value = atan(dpy / dpx) - π
        }
    } else {
        if point.y > 0.0 {
            value =  Half_π
        }
        else if point.y < 0.0 {
            value =  -Half_π
        }
        else {
            value = 0.0
        }
    }
    return NormalizeAngle(value)
}

// ===================================
// MARK: ---- Angle Range ----
// ===================================

//////////////////////////////////////////////////////////////////////////
// Angle Range structure provides a simple way to store angle ranges
//  and determine if a specific angle falls within.
//
struct BPAngleRange {
    var minimum: Double
    var maximum: Double
}

func BPIsValueGreaterThan(_ value: CGFloat, minimum: CGFloat) -> Bool {
    return BPIsValueGreaterThanWithOptions(Double(value), minimum: Double(minimum), threshold: BPTangentClosenessThreshold)
}

func BPIsValueGreaterThanWithOptions(_ value: Double, minimum: Double, threshold: Double) -> Bool {
    if BPAreValuesCloseWithOptions(value, value2: minimum, threshold: threshold) {
        return false
    }
    return value > minimum
}

func BPIsValueGreaterThan(_ value: Double, minimum: Double) -> Bool {
    return BPIsValueGreaterThanWithOptions(value, minimum: minimum, threshold: Double(BPTangentClosenessThreshold))
}

func BPIsValueLessThan(_ value: CGFloat, maximum: CGFloat) -> Bool {
    if BPAreValuesCloseWithOptions(Double(value), value2: Double(maximum), threshold: BPTangentClosenessThreshold) {
        return false
    }
    return value < maximum
}

func BPIsValueLessThan(_ value: Double, maximum: Double) -> Bool {
    if BPAreValuesCloseWithOptions(value, value2: maximum, threshold: Double(BPTangentClosenessThreshold)) {
        return false
    }
    return value < maximum
}

func BPIsValueGreaterThanEqual(_ value: CGFloat, minimum: CGFloat) -> Bool {
    if BPAreValuesCloseWithOptions(Double(value), value2: Double(minimum), threshold: BPTangentClosenessThreshold) {
        return true
    }
    return value >= minimum
}

func BPIsValueGreaterThanEqual(_ value: Double, minimum: Double) -> Bool {
    if BPAreValuesCloseWithOptions(value, value2: minimum, threshold: Double(BPTangentClosenessThreshold)) {
        return true
    }
    return value >= minimum
}

func BPIsValueLessThanEqualWithOptions(_ value: Double, maximum: Double, threshold: Double) -> Bool {
    if BPAreValuesCloseWithOptions(value, value2: maximum, threshold: threshold) {
        return true
    }
    return value <= maximum
}

func BPIsValueLessThanEqual(_ value: CGFloat, maximum: CGFloat) -> Bool {
    return BPIsValueLessThanEqualWithOptions(Double(value), maximum: Double(maximum), threshold: BPTangentClosenessThreshold)
}

func BPIsValueLessThanEqual(_ value: Double, maximum: Double) -> Bool {
    return BPIsValueLessThanEqualWithOptions(value, maximum: maximum, threshold: BPTangentClosenessThreshold)
}

func BPAngleRangeContainsAngle(_ range: BPAngleRange, angle: Double) -> Bool {
    if range.minimum <= range.maximum {
        return BPIsValueGreaterThan(angle, minimum: range.minimum) && BPIsValueLessThan(angle, maximum: range.maximum)
    }
    if BPIsValueGreaterThan(angle, minimum: range.minimum) && angle <= Two_π {
        return true
    }
    return angle >= 0.0 && BPIsValueLessThan(angle, maximum: range.maximum)
}

// ===================================
// MARK: Parameter ranges
// ===================================

struct BPRange {
    var minimum: Double
    var maximum: Double
}

func BPRangeHasConverged(_ range: BPRange, decimalPlaces: Int) -> Bool {
    let factor = pow(10.0, Double(decimalPlaces))
    let minimum = Int(range.minimum * factor)
    let maxiumum = Int(range.maximum * factor)
    return minimum == maxiumum
}

func BPRangeGetSize(_ range: BPRange) -> Double {
    return range.maximum - range.minimum
}

func BPRangeAverage(_ range: BPRange) -> Double {
    return (range.minimum + range.maximum) / 2.0
}

func BPRangeScaleNormalizedValue(_ range: BPRange, value: Double) -> Double {
    return (range.maximum - range.minimum) * value + range.minimum
}

func BPRangeUnion(_ range1: BPRange, range2: BPRange) -> BPRange {
    return BPRange(minimum: min(range1.minimum, range2.minimum), maximum: max(range1.maximum, range2.maximum))
}

// ===================================
// MARK: Tangents
// ===================================

struct BPTangentPair {
    var left: CGPoint
    var right: CGPoint
}

func BPAreTangentsAmbigious(_ edge1Tangents: BPTangentPair, edge2Tangents: BPTangentPair) -> Bool {
    let normalEdge1 = BPTangentPair(left: BPNormalizePoint(edge1Tangents.left), right: BPNormalizePoint(edge1Tangents.right))
    let normalEdge2 = BPTangentPair(left: BPNormalizePoint(edge2Tangents.left), right: BPNormalizePoint(edge2Tangents.right))
    
    return BPArePointsCloseWithOptions(normalEdge1.left,  point2: normalEdge2.left,  threshold: BPTangentClosenessThreshold)
        || BPArePointsCloseWithOptions(normalEdge1.left,  point2: normalEdge2.right, threshold: BPTangentClosenessThreshold)
        || BPArePointsCloseWithOptions(normalEdge1.right, point2: normalEdge2.left,  threshold: BPTangentClosenessThreshold)
        || BPArePointsCloseWithOptions(normalEdge1.right, point2: normalEdge2.right, threshold: BPTangentClosenessThreshold)
}

struct BPAnglePair {
    var a: Double
    var b: Double
}

func BPTangentsCross(_ edge1Tangents: BPTangentPair, edge2Tangents: BPTangentPair) -> Bool {
    let edge1Angles = BPAnglePair(a: PolarAngle(edge1Tangents.left), b: PolarAngle(edge1Tangents.right))
    let edge2Angles = BPAnglePair(a: PolarAngle(edge2Tangents.left), b: PolarAngle(edge2Tangents.right))
    
    let range1 = BPAngleRange(minimum: edge1Angles.a, maximum: edge1Angles.b)
    var rangeCount1 = 0
    
    if BPAngleRangeContainsAngle(range1, angle: edge2Angles.a) {
        rangeCount1 += 1
    }
    if BPAngleRangeContainsAngle(range1, angle: edge2Angles.b) {
        rangeCount1 += 1
    }
    let range2 = BPAngleRange(minimum: edge1Angles.b, maximum: edge1Angles.a)
    var rangeCount2 = 0
    
    if BPAngleRangeContainsAngle(range2, angle: edge2Angles.a) {
        rangeCount2 += 1
    }
    if BPAngleRangeContainsAngle(range2, angle: edge2Angles.b) {
        rangeCount2 += 1
    }
    return rangeCount1 == 1 && rangeCount2 == 1
}


func BPLineBoundsMightOverlap(_ bounds1: CGRect, bounds2: CGRect) -> Bool {
    let left = Double(max(bounds1.minX, bounds2.minX))
    let right = Double(min(bounds1.maxX, bounds2.maxX))
    
    if BPIsValueGreaterThanWithOptions(left, minimum: right, threshold: BPBoundsClosenessThreshold) {
        return false    // no horizontal overlap
    }
    
    let top = Double(max(bounds1.minY, bounds2.minY))
    let bottom = Double(min(bounds1.maxY, bounds2.maxY))
    return BPIsValueLessThanEqualWithOptions(top, maximum: bottom, threshold: BPBoundsClosenessThreshold)
}
