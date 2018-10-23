//
//  BPBezierCurve.swift
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

struct BPNormalizedLine {
    var a: Double
    var b: Double
    var c: Double
    
    init(a: Double, b: Double, c: Double) {
        self.a = a
        self.b = b
        self.c = c
    }

    init(point1: CGPoint, point2: CGPoint) {
        self.a = Double(point1.y - point2.y)
        self.b = Double(point2.x - point1.x)
        self.c = Double(point1.x * point2.y - point2.x * point1.y)
        
        let distance = sqrt(self.b * self.b + self.a * self.a)

        if distance != 0.0 {
            self.a /= distance
            self.b /= distance
            self.c /= distance
        } else {
            self.a = 0
            self.b = 0
            self.c = 0
        }
    }

    func copyWithOffset(_ offset: Double) -> BPNormalizedLine {
        return BPNormalizedLine(
            a: self.a,
            b: self.b,
            c: self.c + offset)
    }

    func distanceFromPoint(_ point: CGPoint) -> Double {
        return a * Double(point.x) + b * Double(point.y) + c;
    }
    
    func intersectionWith(_ other: BPNormalizedLine) -> CGPoint {
        let denominator = (self.a * other.b) - (other.a * self.b)
        
        return CGPoint(
            x: (self.b * other.c - other.b * self.c) / denominator,
            y: (self.a * other.c - other.a * self.c) / denominator)
    }
}

// ========================================================
// MARK: ---- Helper Functions
// ========================================================

func BPParameterOfPointOnLine(_ lineStart: CGPoint, lineEnd: CGPoint, point: CGPoint) -> Double {
    
    let lineLength = BPDistanceBetweenPoints(lineStart, point2: lineEnd)
    let lengthFromStart = BPDistanceBetweenPoints(point, point2: lineStart)
    var parameter = lengthFromStart / lineLength
    
    let lengthFromEnd = BPDistanceBetweenPoints(point, point2: lineEnd)
    if BPAreValuesClose(lineLength + lengthFromStart, value2: lengthFromEnd) {
        parameter *= -1
    }
    return parameter
}

func BPLinesIntersect(_ line1Start: CGPoint, line1End: CGPoint, line2Start: CGPoint, line2End: CGPoint, outIntersect: inout CGPoint) -> Bool {
    let line1 = BPNormalizedLine(point1: line1Start, point2: line1End)
    let line2 = BPNormalizedLine(point1: line2Start, point2: line2End)
    outIntersect = line1.intersectionWith(line2)
    if outIntersect.x.isNaN || outIntersect.y.isNaN {
        return false
    }
    outIntersect.y = -outIntersect.y
    return true
}

func CounterClockwiseTurn(_ point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
    let xDeltaA = Double(point2.x - point1.x)
    let yDeltaB = Double(point3.y - point1.y)
    let yDeltaC = Double(point2.y - point1.y)
    let xDeltaD = Double(point3.x - point1.x)
    return xDeltaA * yDeltaB - yDeltaC * xDeltaD
}

func LineIntersectsHorizontalLine(_ startPoint: CGPoint, endPoint: CGPoint, y: Double, intersectPoint: inout CGPoint) -> Bool {
    let minY = Double(min(startPoint.y, endPoint.y))
    let maxY = Double(max(startPoint.y, endPoint.y))
    if (y < minY && !BPAreValuesClose(y, value2: minY)) || (y > maxY && !BPAreValuesClose(y, value2: maxY)) {
        return false
    }

    if startPoint.x == endPoint.x {
        intersectPoint = CGPoint(x: startPoint.x, y: CGFloat(y))
    }
    else {
        let slope = Double(endPoint.y - startPoint.y) / Double(endPoint.x - startPoint.x)
        intersectPoint = CGPoint(
            x: CGFloat((y - Double(startPoint.y)) / slope) + startPoint.x,
            y: CGFloat(y))
    }
    return true
}

func BezierWithPoints(_ degree: Int, bezierPoints: [CGPoint], parameter: Double, withCurves: Bool) -> (point: CGPoint, leftCurve: [CGPoint]?, rightCurve: [CGPoint]?) {
    
    var points: [CGPoint] = []
    
    for i in 0 ... degree {
        points.append(bezierPoints[i])
    }
    
    var leftArray = [CGPoint](repeating: CGPoint.zero, count: degree+1)
    var rightArray = [CGPoint](repeating: CGPoint.zero, count: degree+1)
    
    if withCurves {
        leftArray[0] = points[0]
        rightArray[degree] = points[degree]
    }
    
    for k in 1 ... degree {
        for i in 0 ... (degree - k) {
            let pxV = (1.0 - parameter) * Double(points[i].x) + parameter * Double(points[i + 1].x)
            points[i].x = CGFloat(pxV)
            let pyV = (1.0 - parameter) * Double(points[i].y) + parameter * Double(points[i + 1].y)
            points[i].y = CGFloat(pyV)
        }
        if withCurves {
            leftArray[k] = points[0]
            rightArray[degree-k] = points[degree-k]
        }
    }
    
    return (point: points[0], leftCurve: leftArray, rightCurve: rightArray)
}

func BPComputeCubicFirstDerivativeRoots(_ a: Double, b: Double, c: Double, d: Double) -> [Double] {
    
    let denominator = -a + 3.0 * b - 3.0 * c + d
    
    if BPAreValuesClose(denominator, value2: 0.0) {
        let t = (a - b) / (2.0 * (a - 2.0 * b + c))
        return [t];
    }
    
    let numeratorLeft = -a + 2.0 * b - c
    
    let v1 = -a * (c - d)
    let v2 = b * b
    let v3 = b * (c + d)
    let v4 = c * c
    let numeratorRight = -1.0 * sqrt(v1 + v2 - v3 + v4)
    
    let t1 = (numeratorLeft + numeratorRight) / denominator
    let t2 = (numeratorLeft - numeratorRight) / denominator
    return [t1, t2]
}

func BPGaussQuadratureBaseForCubic(_ t: Double, p1: Double, p2: Double, p3: Double, p4: Double) -> Double {
    let t1 = (-3.0 * p1) + (9.0 * p2) - (9.0 * p3) + (3.0 * p4)
    let t2 = t * t1 + 6.0 * p1 - 12.0 * p2 + 6.0 * p3
    
    return t * t2 - 3.0 * p1 + 3.0 * p2
    //return t * (t * (-3 * p1 + 9 * p2 - 9 * p3 + 3 * p4) + 6 * p1 + 12 * p2 + 3 * p3) - 3 * p1 + 3 * p2
}

func BPGaussQuadratureFOfTForCubic(_ t: Double, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> Double {
    let baseX = BPGaussQuadratureBaseForCubic(t,
                                              p1: Double(p1.x),
                                              p2: Double(p2.x),
                                              p3: Double(p3.x),
                                              p4: Double(p4.x))
    let baseY = BPGaussQuadratureBaseForCubic(t,
                                              p1: Double(p1.y),
                                              p2: Double(p2.y),
                                              p3: Double(p3.y),
                                              p4: Double(p4.y))
    
    return sqrt(baseX * baseX + baseY * baseY)
}

func BPGaussQuadratureComputeCurveLengthForCubic(_ z: Double, steps: Int, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> Double {
    let z2 = Double(z / 2.0)
    var sum: Double = 0.0
    for i in 0 ..< steps {
        let correctedT: Double = z2 * BPLegendreGaussAbscissaeValues[steps][i] + z2
        sum += BPLegendreGaussWeightValues[steps][i] * BPGaussQuadratureFOfTForCubic(correctedT, p1: p1, p2: p2, p3: p3, p4: p4)
    }
    return z2 * sum
}

func BPSign(_ value: CGFloat) -> Int {
    if value < 0.0 {
        return -1
    } else {
        return 1
    }
}

func BPCountBezierCrossings(_ bezierPoints: [CGPoint], degree: Int) -> Int {
    var count: Int = 0
    var sign = BPSign(bezierPoints[0].y)
    
    var previousSign = sign
    for i in 1 ... degree {
        sign = BPSign(bezierPoints[i].y)
        if sign != previousSign {
            count += 1
        }
        previousSign = sign;
    }
    return count
}

let BPFindBezierRootsMaximumDepth = 64

func BPIsControlPolygonFlatEnough(_ bezierPoints: [CGPoint], degree: Int, intersectionPoint: inout CGPoint) -> Bool {
    
    let BPFindBezierRootsErrorThreshold = CGFloat(ldexpf(Float(1.0), Int32(-1 * (BPFindBezierRootsMaximumDepth - 1))))
    let line = BPNormalizedLine(point1: bezierPoints[0], point2: bezierPoints[degree])
    
    var belowDistance = 0.0
    var aboveDistance = 0.0
    for i in 1 ..< degree {
        let distance = line.distanceFromPoint(bezierPoints[i])
        if distance > aboveDistance {
            aboveDistance = distance
        }
        if distance < belowDistance {
            belowDistance = distance
        }
    }
    
    let zeroLine = BPNormalizedLine(a: 0.0, b: 1.0, c: 0.0)
    let aboveLine = line.copyWithOffset(-aboveDistance)
    let intersect1 = zeroLine.intersectionWith(aboveLine)
    
    let belowLine = line.copyWithOffset(-belowDistance)
    let intersect2 = zeroLine.intersectionWith(belowLine)
    
    let error = max(intersect1.x, intersect2.x) - min(intersect1.x, intersect2.x)
    if error < BPFindBezierRootsErrorThreshold {
        intersectionPoint = zeroLine.intersectionWith(line)
        return true
    }
    return false
}

func BPFindBezierRootsWithDepth(_ bezierPoints: [CGPoint], degree: Int, depth: Int, perform: (_ root: Double) -> Void) {
    let crossingCount = BPCountBezierCrossings(bezierPoints, degree: degree)
    if crossingCount == 0 {
        return
    }
    else if crossingCount == 1 {
        if depth >= BPFindBezierRootsMaximumDepth {
            let root = Double(bezierPoints[0].x + bezierPoints[degree].x) / 2.0
            perform(root)
            return
        }
        var intersectionPoint = CGPoint.zero
        if BPIsControlPolygonFlatEnough(bezierPoints, degree: degree, intersectionPoint: &intersectionPoint) {
            perform(Double(intersectionPoint.x))
            return
        }
    }
    
    let bwp = BezierWithPoints(degree, bezierPoints: bezierPoints, parameter: 0.5, withCurves: true)
    BPFindBezierRootsWithDepth(bwp.leftCurve!, degree: degree, depth: depth + 1, perform: perform)
    BPFindBezierRootsWithDepth(bwp.rightCurve!, degree: degree, depth: depth + 1, perform: perform)
}

func BPFindBezierRoots(_ bezierPoints: [CGPoint], degree: Int, perform: (_ root: Double) -> Void) {
    
    BPFindBezierRootsWithDepth(bezierPoints, degree: degree, depth: 0, perform: perform)
}

// ========================================================
// MARK: ---- Convex Hull ----
// ========================================================

func BPConvexHullDoPointsTurnWrongDirection(_ point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Bool {
    
    let area = CounterClockwiseTurn(point1, point2: point2, point3: point3)
    return BPAreValuesClose(area, value2: 0.0) || area < 0.0
}

func BPConvexHullBuildFromPoints(_ inPoints: [CGPoint]) -> (hull: [CGPoint], hullLength: Int) {

    let numberOfPoints = 4
    var points = inPoints
    
    var sortLength = numberOfPoints
    repeat {
        var newSortLength = 0
        for i in 1 ..< sortLength {
            if ( points[i - 1].x > points[i].x || (BPAreValuesClose(points[i - 1].x, value2: points[i].x) && points[i - 1].y > points[i].y) ) {
                let tempPoint = points[i]
                points[i] = points[i - 1]
                points[i - 1] = tempPoint
                newSortLength = i
            }
        }
        sortLength = newSortLength
    } while sortLength > 0
    
    var filledInIx = 0
    var results = [CGPoint](repeating: CGPoint.zero, count: 8)
    
    for i in 0 ..< numberOfPoints {
        while filledInIx >= 2 && BPConvexHullDoPointsTurnWrongDirection(results[filledInIx - 2], point2: results[filledInIx - 1], point3: points[i]) {
            filledInIx -= 1
        }
        results[filledInIx] = points[i];
        filledInIx += 1;
    }
    
    let thresholdIndex = filledInIx + 1
    for i in (0 ... numberOfPoints - 2).reversed() {
        while filledInIx >= thresholdIndex && BPConvexHullDoPointsTurnWrongDirection(results[filledInIx - 2], point2: results[filledInIx - 1], point3: points[i]) {
            filledInIx -= 1
        }
        
        results[filledInIx] = points[i];
        filledInIx += 1;
    }
    
    return (hull: results, hullLength: filledInIx - 1)
}

func ILLUSTRATE_CALL_TO_BPConvexHullBuildFromPoints() {
    let distanceBezierPoints = [CGPoint](repeating: CGPoint.zero, count: 4)
    
    let (_, convexHullLength) = BPConvexHullBuildFromPoints(distanceBezierPoints)
    
    if convexHullLength < 0 {
        print("YIKES")
    }
}

// ========================================================
// MARK: ---- BPBezierCurveData ----
// ========================================================


struct BPBezierCurveLocation {
    var parameter: Double
    var distance: Double
    
    init(parameter: Double, distance: Double) {
        self.parameter = parameter
        self.distance = distance
    }
}

class BPBezierCurveData {
    var endPoint1: CGPoint
    var controlPoint1: CGPoint
    var controlPoint2: CGPoint
    var endPoint2: CGPoint
    
    var isStraightLine: Bool
    
    var length: Double?
    fileprivate var _bounds: CGRect?
    var _isPoint: Bool?
    var _boundingRect: CGRect?
    
    init(endPoint1: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint, endPoint2: CGPoint, isStraightLine: Bool) {
        self.endPoint1 = endPoint1
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
        self.endPoint2 = endPoint2
        self.isStraightLine = isStraightLine
        
        self.length = BPBezierCurveDataInvalidLength
    }
    
    init(cloning clone: BPBezierCurveData) {
        self.endPoint1 = clone.endPoint1
        self.controlPoint1 = clone.controlPoint1
        self.controlPoint2 = clone.controlPoint2
        self.endPoint2 = clone.endPoint2
        self.isStraightLine = clone.isStraightLine
        
        self.length = clone.length
    }
    
    func isPoint() -> Bool {
        let BPClosenessThreshold = isRunningOn64BitDevice ? 1e-5 : 1e-1
        
        if _isPoint != nil {
            return _isPoint!
        }
        
        _isPoint = BPArePointsCloseWithOptions(endPoint1, point2: endPoint2, threshold: BPClosenessThreshold) && BPArePointsCloseWithOptions(endPoint1, point2: controlPoint1, threshold: BPClosenessThreshold) && BPArePointsCloseWithOptions(endPoint1, point2: controlPoint2, threshold: BPClosenessThreshold)
        
        return _isPoint!;
    }

    var boundingRect: CGRect {
        // Use the cache if we have one
        if _boundingRect != nil {
            return _boundingRect!
        }
        
        let left = min(endPoint1.x, min(controlPoint1.x, min(controlPoint2.x, endPoint2.x)))
        let top = min(endPoint1.y, min(controlPoint1.y, min(controlPoint2.y, endPoint2.y)))
        let right = max(endPoint1.x, max(controlPoint1.x, max(controlPoint2.x, endPoint2.x)))
        let bottom = max(endPoint1.y, max(controlPoint1.y, max(controlPoint2.y, endPoint2.y)))
        
        _boundingRect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        
        return _boundingRect!
    }

    var bounds: CGRect {
        if _bounds != nil {
            return _bounds!
        }
        
        var bounds = CGRect.zero
        
        if isStraightLine {
            var topLeft = endPoint1
            var bottomRight = topLeft
            BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: endPoint2)
            
            bounds = CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
        } else {
            var (topLeft, _, _) = pointAtParameter(0)
            var bottomRight = topLeft
            let (lastPoint, _, _) = pointAtParameter(1)
            
            BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: lastPoint);
            
            let xRoots: [Double] = BPComputeCubicFirstDerivativeRoots(Double(endPoint1.x), b: Double(controlPoint1.x), c: Double(controlPoint2.x), d: Double(endPoint2.x))
            
            for i in 0 ..< xRoots.count {
                let t = xRoots[i]
                if t < 0 || t > 1 {
                    continue
                }
                let (location, _, _) = pointAtParameter(t)
                BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: location)
            }
            
            let yRoots: [Double] = BPComputeCubicFirstDerivativeRoots(Double(endPoint1.y), b: Double(controlPoint1.y), c: Double(controlPoint2.y), d: Double(endPoint2.y))
            for i in 0 ..< yRoots.count {
                let t = yRoots[i]
                if t < 0 || t > 1 {
                    continue
                }
                let (location, _, _) = pointAtParameter(t)
                BPExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: location)
            }
            
            bounds = CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
        }
        
        _bounds = bounds
        return bounds
    }
    
    func getLengthAtParameter(_ parameter: Double) -> Double {
    
        if parameter == 1.0 && length != nil && length != BPBezierCurveDataInvalidLength {
            return length!
        }
    
        var calculatedLength = BPBezierCurveDataInvalidLength;
        if isStraightLine {
            calculatedLength = BPDistanceBetweenPoints(endPoint1, point2: endPoint2) * parameter
        } else {
            calculatedLength = BPGaussQuadratureComputeCurveLengthForCubic(Double(parameter), steps: 12, p1: endPoint1, p2: controlPoint1, p3: controlPoint2, p4: endPoint2)
        }
        
        if parameter == 1.0 {
            length = calculatedLength
        }
        
        return calculatedLength
    }
    
    func reversed() -> BPBezierCurveData {
        return BPBezierCurveData(endPoint1: endPoint2, controlPoint1: controlPoint2, controlPoint2: controlPoint1, endPoint2: endPoint1, isStraightLine: isStraightLine)
    }

    func getLength() -> Double {
        return getLengthAtParameter(1.0)
    }

    func pointAtParameter(_ parameter: Double) -> (point: CGPoint, leftCurve: BPBezierCurveData?, rightCurve: BPBezierCurveData?) {
        let points = [endPoint1, controlPoint1, controlPoint2, endPoint2]
        
        let bwp = BezierWithPoints(3, bezierPoints: points, parameter: parameter, withCurves: true);
        
        var leftBCData: BPBezierCurveData? = nil
        if let leftA = bwp.leftCurve {
            leftBCData = BPBezierCurveData(endPoint1: leftA[0], controlPoint1: leftA[1], controlPoint2: leftA[2], endPoint2: leftA[3], isStraightLine: isStraightLine)
        }
        
        var rightBCData: BPBezierCurveData? = nil
        if let rightA = bwp.rightCurve {
            rightBCData = BPBezierCurveData(endPoint1: rightA[0], controlPoint1: rightA[1], controlPoint2: rightA[2], endPoint2: rightA[3], isStraightLine: isStraightLine)
        }
        
        
        return (point: bwp.point, leftCurve: leftBCData, rightCurve: rightBCData)
    }

    func subcurveWithRange(_ range: BPRange) -> BPBezierCurveData {
        let upperCurve = self.pointAtParameter(range.minimum).rightCurve!
        
        if range.minimum == 1.0 {
            return upperCurve           // avoid the divide by zero below
        }

        let adjustedMaximum = (range.maximum - range.minimum) / (1.0 - range.minimum)
        
        let lowerCurve = upperCurve.pointAtParameter(adjustedMaximum).leftCurve!
        
        return lowerCurve
    }
   
    func regularFatLineBounds() -> (line: BPNormalizedLine, range: BPRange) {
 
        let line = BPNormalizedLine(point1: endPoint1, point2: endPoint2)
     
        let controlPoint1Distance = line.distanceFromPoint(controlPoint1)
        let controlPoint2Distance = line.distanceFromPoint(controlPoint2)
        
        let minim = min(controlPoint1Distance, min(controlPoint2Distance, 0.0))
        let maxim = max(controlPoint1Distance, max(controlPoint2Distance, 0.0))
        
        return (line, BPRange(minimum: minim, maximum: maxim))
    }
    
 
    func perpendicularFatLineBounds() -> (line: BPNormalizedLine, range: BPRange) {
       
        let normal = BPLineNormal(endPoint1, lineEnd: endPoint2)
        let startPoint = BPLineMidpoint(endPoint1, lineEnd: endPoint2)
        let endPoint = BPAddPoint(startPoint, point2: normal)
        let line = BPNormalizedLine(point1: startPoint, point2: endPoint)
        
        let controlPoint1Distance = line.distanceFromPoint(controlPoint1)
        let controlPoint2Distance = line.distanceFromPoint(controlPoint2)
        let point1Distance = line.distanceFromPoint(endPoint1)
        let point2Distance = line.distanceFromPoint(endPoint2)
        
        let minim = min(controlPoint1Distance, min(controlPoint2Distance, min(point1Distance, point2Distance)))
        let maxim = max(controlPoint1Distance, max(controlPoint2Distance, max(point1Distance, point2Distance)))
        
        return (line, BPRange(minimum: minim, maximum: maxim))
    }
    
    func clipWithFatLine(_ fatLine: BPNormalizedLine, bounds: BPRange) -> BPRange {
        let distanceBezierPoints: [CGPoint] = [
            CGPoint(x: 0.0, y: fatLine.distanceFromPoint(endPoint1)),
            CGPoint(x: 1.0 / 3.0, y: fatLine.distanceFromPoint(controlPoint1)),
            CGPoint(x: 2.0 / 3.0, y: fatLine.distanceFromPoint(controlPoint2)),
            CGPoint(x: 1.0, y: fatLine.distanceFromPoint(endPoint2))
        ]
        
        let (convexHull, convexHullLength) = BPConvexHullBuildFromPoints(distanceBezierPoints)

        var range = BPRange(minimum: 1.0, maximum: 0.0)
        
        for i in 0 ..< convexHullLength {
            let indexOfNext = i < (convexHullLength - 1) ? i + 1 : 0
            
            let startPoint = convexHull[i]
            let endPoint = convexHull[indexOfNext]
            var intersectionPoint = CGPoint.zero
            
            if LineIntersectsHorizontalLine(startPoint, endPoint: endPoint, y: bounds.minimum, intersectPoint: &intersectionPoint) {
                if Double(intersectionPoint.x) < range.minimum {
                    range.minimum = Double(intersectionPoint.x)
                }
                if Double(intersectionPoint.x) > range.maximum {
                    range.maximum = Double(intersectionPoint.x)
                }
            }
         
            if LineIntersectsHorizontalLine(startPoint, endPoint: endPoint, y: bounds.maximum, intersectPoint: &intersectionPoint) {
                if Double(intersectionPoint.x) < range.minimum {
                    range.minimum = Double(intersectionPoint.x)
                }
                if Double(intersectionPoint.x) > range.maximum {
                    range.maximum = Double(intersectionPoint.x)
                }
            }
          
            if Double(startPoint.y) < bounds.maximum && Double(startPoint.y) > bounds.minimum {
                if Double(startPoint.x) < range.minimum {
                    range.minimum = Double(startPoint.x)
                }
                if Double(startPoint.x) > range.maximum {
                    range.maximum = Double(startPoint.x)
                }
            }
        }
        
        if range.minimum.isInfinite || range.minimum.isNaN || range.maximum.isInfinite || range.maximum.isNaN {
            range = BPRange(minimum: 0, maximum: 1); // equivalent to: something went wrong, so I don't know
        }
        
        return range
    }
    
    func convertSelfAndPoint(_ point: CGPoint) -> [CGPoint] {
        var selfPoints: [CGPoint] = [endPoint1, controlPoint1, controlPoint2, endPoint2]
        
        let distanceFromPoint = [
            BPSubtractPoint(selfPoints[0], point2: point),
            BPSubtractPoint(selfPoints[1], point2: point),
            BPSubtractPoint(selfPoints[2], point2: point),
            BPSubtractPoint(selfPoints[3], point2: point)
        ]
        
        let weightedDelta = [
            BPScalePoint(BPSubtractPoint(selfPoints[1], point2: selfPoints[0]), scale: 3),
            BPScalePoint(BPSubtractPoint(selfPoints[2], point2: selfPoints[1]), scale: 3),
            BPScalePoint(BPSubtractPoint(selfPoints[3], point2: selfPoints[2]), scale: 3)
        ]
        
        var precomputedTable: [[Double]] = [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0]
        ]
        for row in 0 ..< 3 {
            for column in 0 ..< 4 {
                precomputedTable[row][column] = BPDotMultiplyPoint(weightedDelta[row], point2: distanceFromPoint[column])
            }
        }
        
        let BPZ: [[Double]] = [
            [1.0, 0.6, 0.3, 0.1],
            [0.4, 0.6, 0.6, 0.4],
            [0.1, 0.3, 0.6, 1.0]
        ]
        
        var bezierPoints = [CGPoint](repeating: CGPoint.zero, count: 6)
        
        for i in 0 ..< 6 {
            bezierPoints[i] = CGPoint(x: CGFloat(i) / 5.0, y: 0)
        }
        
        let n = 3
        let m = n - 1
        for k in 0 ... (n + m) {
            let lowerBound = max(0, k - m)
            let upperBound = min(k, n)
            for i in lowerBound ... upperBound {
                let j = k - i
                bezierPoints[i + j].y += CGFloat(precomputedTable[j][i] * BPZ[j][i])
            }
        }
        
        return bezierPoints
    }
    
    func closestLocationToPoint(_ point: CGPoint) -> BPBezierCurveLocation {
        let bezierPoints = convertSelfAndPoint(point)
        
        var distance = BPDistanceBetweenPoints(endPoint1, point2: point)
        var parameter = 0.0
        
        BPFindBezierRoots(bezierPoints, degree: 5) { (root) -> Void in
            
            let location = self.pointAtParameter(root).point
            let theDistance = BPDistanceBetweenPoints(location, point2: point)
            if ( theDistance < distance ) {
                distance = theDistance
                parameter = root
            }
        }
        
        let lastDistance = BPDistanceBetweenPoints(endPoint2, point2: point)
        if ( lastDistance < distance ) {
            distance = lastDistance;
            parameter = 1.0;
        }
        
        let location = BPBezierCurveLocation(parameter: parameter, distance: distance)
        
        return location
    }
    
    func isEqualWithOptions(_ other: BPBezierCurveData, threshold: Double) -> Bool {
        if isPoint() || other.isPoint() {
            return false
        }
        if isStraightLine != other.isStraightLine {
            return false
        }
        if isStraightLine {
            return BPArePointsCloseWithOptions(endPoint1, point2: other.endPoint1, threshold: threshold) && BPArePointsCloseWithOptions(endPoint2, point2: other.endPoint2, threshold: threshold)
        }
        return BPArePointsCloseWithOptions(endPoint1, point2: other.endPoint1, threshold: threshold) && BPArePointsCloseWithOptions(controlPoint1, point2: other.controlPoint1, threshold: threshold) && BPArePointsCloseWithOptions(controlPoint2, point2: other.controlPoint2, threshold: threshold) && BPArePointsCloseWithOptions(endPoint2, point2: other.endPoint2, threshold: threshold)
    }
    
}

// ==================================================
// MARK: Private BPBezierCurveData functions
// ==================================================


func bezierClipWithBezierCurve(_ me: BPBezierCurveData,
                               curve: BPBezierCurveData,
                               originalCurve: inout BPBezierCurveData,
                               originalRange: inout BPRange) -> (clipped: BPBezierCurveData, intersects: Bool) {
    let (fatLine, fatLineBounds) = curve.regularFatLineBounds()
    let regularClippedRange = me.clipWithFatLine(fatLine, bounds: fatLineBounds)
    
    if regularClippedRange.minimum == 1.0 && regularClippedRange.maximum == 0.0 {
        return (clipped: me, intersects: false)
    }

    let (perpendicularLine, perpendicularLineBounds) = curve.perpendicularFatLineBounds()
    let perpendicularClippedRange = me.clipWithFatLine(perpendicularLine, bounds: perpendicularLineBounds)
    
    if perpendicularClippedRange.minimum == 1.0 && perpendicularClippedRange.maximum == 0.0 {
        return (clipped: me, intersects: false)
    }
  
    let clippedRange = BPRange(
        minimum: max(regularClippedRange.minimum, perpendicularClippedRange.minimum),
        maximum: min(regularClippedRange.maximum, perpendicularClippedRange.maximum))

    let newRange = BPRange(
        minimum: BPRangeScaleNormalizedValue(originalRange, value: clippedRange.minimum),
        maximum: BPRangeScaleNormalizedValue(originalRange, value: clippedRange.maximum))
    
    originalRange.minimum = newRange.minimum
    originalRange.maximum = newRange.maximum

    return (clipped: originalCurve.subcurveWithRange(originalRange), intersects: true)
}

// ========================================================
// NOTE: Need to decide whether this needs to be static
// ========================================================

private func refineIntersectionsOverIterations(_ iterations: Int,
                                               usRange: inout BPRange,
                                               themRange: inout BPRange,
                                               originalUs: inout BPBezierCurveData,
                                               originalThem: inout BPBezierCurveData,
                                               us: inout BPBezierCurveData,
                                               them: inout BPBezierCurveData,
                                               nonpointUs: inout BPBezierCurveData,
                                               nonpointThem: inout BPBezierCurveData) {
    for _ in 0..<iterations {
        var intersects = false
        
        (us, intersects) = bezierClipWithBezierCurve(us, curve: them, originalCurve: &originalUs, originalRange: &usRange)
        if !intersects {
            (us, intersects) = bezierClipWithBezierCurve(nonpointUs, curve: nonpointThem, originalCurve: &originalUs, originalRange: &usRange)
        }
        
        (them, intersects) = bezierClipWithBezierCurve(them, curve: us, originalCurve: &originalThem, originalRange: &themRange)
        if !intersects {
            (them, intersects) = bezierClipWithBezierCurve(nonpointThem, curve: nonpointUs, originalCurve: &originalThem, originalRange: &themRange)
        }
        if !them.isPoint() {
            nonpointThem = them
        }
        if !us.isPoint() {
            nonpointUs = us
        }
    }
}

private func clipLineOriginalCurve(_ originalCurve: BPBezierCurveData,
                                   curve: BPBezierCurveData,
                                   originalRange: inout BPRange,
                                   otherCurve: BPBezierCurveData) -> (clippedCurve: BPBezierCurveData, intersects: Bool) {
    let themOnUs1 = BPParameterOfPointOnLine(curve.endPoint1, lineEnd: curve.endPoint2, point: otherCurve.endPoint1)
    let themOnUs2 = BPParameterOfPointOnLine(curve.endPoint1, lineEnd: curve.endPoint2, point: otherCurve.endPoint2)
    let clippedRange = BPRange(
        minimum: max(0.0, min(themOnUs1, themOnUs2)),
        maximum: min(1.0, max(themOnUs1, themOnUs2)))
    
    if clippedRange.minimum > clippedRange.maximum {
        return (curve, false)
    }
    originalRange = BPRange(
        minimum: BPRangeScaleNormalizedValue(originalRange, value: clippedRange.minimum),
        maximum: BPRangeScaleNormalizedValue(originalRange, value: clippedRange.maximum))
    
    return (originalCurve.subcurveWithRange(originalRange) , true)
}

@discardableResult
private func checkLinesForOverlap(_ me: BPBezierCurveData,
                                  usRange: inout BPRange,
                                  themRange: inout BPRange,
                                  originalUs: BPBezierCurveData,
                                  originalThem: BPBezierCurveData,
                                  us: inout BPBezierCurveData,
                                  them: inout BPBezierCurveData) -> Bool {
    if !BPLineBoundsMightOverlap(us.bounds, bounds2: them.bounds) {
        return false
    }

    let errorThreshold = isRunningOn64BitDevice ? 1e-7 : 1e-2
    
    let isColinear = BPAreValuesCloseWithOptions(
        CounterClockwiseTurn(us.endPoint1, point2: us.endPoint2, point3: them.endPoint1),
        value2: 0.0,
        threshold: errorThreshold)
        && BPAreValuesCloseWithOptions(
            CounterClockwiseTurn(us.endPoint1, point2: us.endPoint2, point3: them.endPoint2),
            value2: 0.0,
            threshold: errorThreshold)
    
    if !isColinear {
        return false
    }
    
    var intersects = false
    (us, intersects) = clipLineOriginalCurve(originalUs, curve: us, originalRange: &usRange, otherCurve: them)

    if !intersects {
        return false
    }
    (them, intersects) = clipLineOriginalCurve(originalThem, curve: them, originalRange: &themRange, otherCurve: us)
    return intersects
}

private func curvesAreEqual(_ me: BPBezierCurveData, other: BPBezierCurveData) -> Bool {
    if me.isPoint() || other.isPoint() {
        return false
    }
    if me.isStraightLine != other.isStraightLine {
        return false
    }
    let endPointThreshold = isRunningOn64BitDevice ? 1e-4 : 1e-2
    let controlPointThreshold = 1e-1
    if me.isStraightLine {
        return BPArePointsCloseWithOptions(me.endPoint1, point2: other.endPoint1, threshold: endPointThreshold) && BPArePointsCloseWithOptions(me.endPoint2, point2: other.endPoint2, threshold: endPointThreshold);
    }
    return BPArePointsCloseWithOptions(me.endPoint1, point2: other.endPoint1, threshold: endPointThreshold)
        && BPArePointsCloseWithOptions(me.controlPoint1, point2: other.controlPoint1, threshold: controlPointThreshold)
        && BPArePointsCloseWithOptions(me.controlPoint2, point2: other.controlPoint2, threshold: controlPointThreshold)
        && BPArePointsCloseWithOptions(me.endPoint2, point2: other.endPoint2, threshold: endPointThreshold);
}

private func dataIsEqual(_ me: BPBezierCurveData, other: BPBezierCurveData) -> Bool {
    let threshold = isRunningOn64BitDevice ? 1e-10 : 1e-2
    return me.isEqualWithOptions(other, threshold: threshold)
}

private func reversed(_ me: BPBezierCurveData) -> BPBezierCurveData {
    return BPBezierCurveData(endPoint1: me.endPoint2, controlPoint1: me.controlPoint2, controlPoint2: me.controlPoint1, endPoint2: me.endPoint1, isStraightLine: me.isStraightLine)
}

@discardableResult
private func checkForOverlapRange(_ me: BPBezierCurveData,
                                  intersectRange: inout BPBezierIntersectRange?,
                                  usRange: inout BPRange,
                                  themRange: inout BPRange,
                                  originalUs: BPBezierCurve,
                                  originalThem: BPBezierCurve,
                                  us: BPBezierCurveData,
                                  them: BPBezierCurveData) -> Bool {
    if curvesAreEqual(us, other: them) {
        intersectRange = BPBezierIntersectRange(curve1: originalUs, parameterRange1: usRange, curve2:originalThem, parameterRange2: themRange, reversed: false)
        return true
    } else if curvesAreEqual(us, other: them.reversed()) {
        intersectRange = BPBezierIntersectRange(curve1: originalUs, parameterRange1: usRange, curve2:originalThem, parameterRange2: themRange, reversed: true)
        return true
    }
    
    return false
}

private func findPossibleOverlap(_ me: BPBezierCurveData,
                                 originalUs: BPBezierCurveData,
                                 them: BPBezierCurveData,
                                 possibleRange: inout BPRange) -> BPBezierCurveData {
    let themOnUs1 = originalUs.closestLocationToPoint(them.endPoint1)
    let themOnUs2 = originalUs.closestLocationToPoint(them.endPoint2)
    let range = BPRange(
        minimum: min(themOnUs1.parameter, themOnUs2.parameter),
        maximum: max(themOnUs1.parameter, themOnUs2.parameter));
    
    possibleRange = range;
    
    return originalUs.subcurveWithRange(range)
}

private func checkCurvesForOverlapRange(_ me: BPBezierCurveData,
                                        intersectRange: inout BPBezierIntersectRange?,
                                        usRange: inout BPRange,
                                        themRange: inout BPRange,
                                        originalUs: BPBezierCurve,
                                        originalThem: BPBezierCurve,
                                        us: BPBezierCurveData,
                                        them: BPBezierCurveData) -> Bool {
    
    if checkForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: us, them: them) {
        return true
    }
    var usSubcurveRange = BPRange(minimum: 0.0, maximum: 0.0)
    let usSubcurve = findPossibleOverlap(me, originalUs: originalUs.data, them: them, possibleRange: &usSubcurveRange)
    
    var themSubcurveRange = BPRange(minimum: 0.0, maximum: 0.0)
    let themSubcurve = findPossibleOverlap(me, originalUs: originalThem.data, them: us, possibleRange: &themSubcurveRange)
    
    let threshold = isRunningOn64BitDevice ? 1e-4 : 1e-2
    if usSubcurve.isEqualWithOptions(themSubcurve, threshold: threshold) || usSubcurve.isEqualWithOptions(reversed(themSubcurve), threshold: threshold) {
        usRange = usSubcurveRange
        themRange = themSubcurveRange
        
        return checkForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: usSubcurve, them: themSubcurve);
    }
    
    return false
}

let BPBezierCurveDataInvalidLength = -1.0

private func checkNoIntersectionsForOverlapRange(_ me: BPBezierCurveData,
                                                 intersectRange: inout BPBezierIntersectRange?,
                                                 usRange: inout BPRange,
                                                 themRange: inout BPRange,
                                                 originalUs: BPBezierCurve,
                                                 originalThem: BPBezierCurve,
                                                 us: inout BPBezierCurveData,
                                                 them: inout BPBezierCurveData,
                                                 nonpointUs: BPBezierCurveData,
                                                 nonpointThem: BPBezierCurveData) {
    
    if us.isStraightLine && them.isStraightLine {
        checkLinesForOverlap(me, usRange: &usRange, themRange: &themRange, originalUs: originalUs.data, originalThem: originalThem.data, us: &us, them: &them)
    }
    
    checkForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: us, them: them)
}

private func straightLineOverlap(_ me: BPBezierCurveData,
                                 intersectRange: inout BPBezierIntersectRange?,
                                 usRange: inout BPRange,
                                 themRange: inout BPRange,
                                 originalUs: BPBezierCurve,
                                 originalThem: BPBezierCurve,
                                 us: inout BPBezierCurveData,
                                 them: inout BPBezierCurveData,
                                 nonpointUs: BPBezierCurveData,
                                 nonpointThem: BPBezierCurveData) -> Bool {
    var hasOverlap = false
    
    if us.isStraightLine && them.isStraightLine {
        hasOverlap = checkLinesForOverlap(me, usRange: &usRange, themRange: &themRange, originalUs: originalUs.data, originalThem: originalThem.data, us: &us, them: &them)
    }
    
    if hasOverlap {
        hasOverlap = checkForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: us, them: them)
    }
    
    return hasOverlap
}

private func pfRefineParameter(_ me: BPBezierCurveData,
                               parameter: Double,
                               point: CGPoint) -> Double {
    
    var bezierPoints: [CGPoint] = [me.endPoint1, me.controlPoint1, me.controlPoint2, me.endPoint2]
    
    let qAtParameter = BezierWithPoints(3, bezierPoints: bezierPoints, parameter: parameter, withCurves: false).point
    
    let qPrimePoints: [CGPoint] = [
        CGPoint(x:(bezierPoints[1].x - bezierPoints[0].x) * 3.0,
                y:(bezierPoints[1].y - bezierPoints[0].y) * 3.0),
        CGPoint(x:(bezierPoints[2].x - bezierPoints[1].x) * 3.0,
                y:(bezierPoints[2].y - bezierPoints[1].y) * 3.0),
        CGPoint(x:(bezierPoints[3].x - bezierPoints[2].x) * 3.0,
                y:(bezierPoints[3].y - bezierPoints[2].y) * 3.0)
    ]
    let qPrimeAtParameter = BezierWithPoints(2, bezierPoints: qPrimePoints, parameter: parameter, withCurves: false).point

    let qPrimePrimePoints: [CGPoint] = [
        CGPoint(
            x: (qPrimePoints[1].x - qPrimePoints[0].x) * 2.0,
            y: (qPrimePoints[1].y - qPrimePoints[0].y) * 2.0
        ),
        CGPoint(
            x: (qPrimePoints[2].x - qPrimePoints[1].x) * 2.0,
            y: (qPrimePoints[2].y - qPrimePoints[1].y) * 2.0
        )
    ]
    let qPrimePrimeAtParameter = BezierWithPoints(1, bezierPoints: qPrimePrimePoints, parameter: parameter, withCurves: false).point
    
    let qMinusPoint = BPSubtractPoint(qAtParameter, point2: point)
    let fAtParameter = BPDotMultiplyPoint(qMinusPoint, point2: qPrimeAtParameter)
    let fPrimeAtParameter = BPDotMultiplyPoint(qMinusPoint, point2: qPrimePrimeAtParameter) + BPDotMultiplyPoint(qPrimeAtParameter, point2: qPrimeAtParameter)
    
    return parameter - (fAtParameter / fPrimeAtParameter)
}

private func mergeIntersectRange(_ intersectRange: BPBezierIntersectRange?,
                                 otherIntersectRange: BPBezierIntersectRange?) -> BPBezierIntersectRange? {
    if otherIntersectRange == nil {
        return intersectRange
    }
    
    if intersectRange == nil {
        return otherIntersectRange
    }
    
    intersectRange!.merge(otherIntersectRange!)
    
    return intersectRange
}

@discardableResult
private func intersectionsWithStraightLines(_ me: BPBezierCurveData,
                                            curve: BPBezierCurveData,
                                            usRange: inout BPRange,
                                            themRange: inout BPRange,
                                            originalUs: BPBezierCurve,
                                            originalThem: BPBezierCurve,
                                            stop: inout Bool,
                                            outputBlock: (_ intersect: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool)) -> Bool {
    if !me.isStraightLine || !curve.isStraightLine {
        return false
    }
    
    var intersectionPoint = CGPoint.zero
    let intersects = BPLinesIntersect(me.endPoint1, line1End: me.endPoint2, line2Start: curve.endPoint1, line2End: curve.endPoint2, outIntersect: &intersectionPoint)
    if !intersects {
        return false
    }
    let meParam = BPParameterOfPointOnLine(me.endPoint1, lineEnd: me.endPoint2, point: intersectionPoint)
    if BPIsValueLessThan(meParam, maximum: 0.0) || BPIsValueGreaterThan(meParam, minimum: 1.0) {
        return false
    }
    let curveParam = BPParameterOfPointOnLine(curve.endPoint1, lineEnd: curve.endPoint2, point: intersectionPoint)
    if BPIsValueLessThan(curveParam, maximum: 0.0) || BPIsValueGreaterThan(curveParam, minimum: 1.0) {
        return false
    }
    let intersect = BPBezierIntersection(curve1: originalUs, param1:meParam, curve2:originalThem, param2:curveParam)
    
    let stopResults = outputBlock(intersect)
    if stopResults.setStop {
        stop = stopResults.stopValue
    }
    return true
}

// ========================================================
// MARK: ---- MAIN SPLIT FUNCTION ----
// ========================================================

internal func pfIntersectionsWithBezierCurve(_ me: BPBezierCurveData,
                                             curve: BPBezierCurveData,
                                             usRange: inout BPRange,
                                             themRange: inout BPRange,
                                             originalUs: BPBezierCurve,
                                             originalThem: BPBezierCurve,
                                             intersectRange: inout BPBezierIntersectRange?,
                                             depth: Int,
                                             stop: inout Bool,
                                             outputBlock: (_ intersect: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool)) {
 
    let places = 6
    let maxIterations = 500
    let maxDepth = 10
    let minimumChangeNeeded = 0.20
    
    var us = BPBezierCurveData(cloning: me)
    var them = BPBezierCurveData(cloning: curve)
   
    var nonpointUs = BPBezierCurveData(cloning: us)
    var nonpointThem = BPBezierCurveData(cloning: them)
    
    if straightLineOverlap(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: &us, them: &them, nonpointUs: nonpointUs, nonpointThem: nonpointThem) {
        return
    }
    
    if us.isStraightLine && them.isStraightLine {
        intersectionsWithStraightLines(me, curve: curve, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, stop: &stop, outputBlock: outputBlock)
        return
    }
    
    var originalUsData = BPBezierCurveData(cloning: originalUs.data)
    var originalThemData = BPBezierCurveData(cloning: originalThem.data)
   
    var iterations = 0
    var hadConverged = true
    
    while ( iterations < maxIterations && ((iterations == 0) || (!BPRangeHasConverged(usRange, decimalPlaces: places) || !BPRangeHasConverged(themRange, decimalPlaces: places))) ) {
        
        let previousUsRange = usRange
        let previousThemRange = themRange
        
        var intersects = false
        if !them.isPoint() {
            nonpointThem = them
        }
        (us, intersects) = bezierClipWithBezierCurve(nonpointUs, curve: nonpointThem, originalCurve: &originalUsData, originalRange: &usRange);
        if !intersects {
            checkNoIntersectionsForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: &us, them: &them, nonpointUs: nonpointUs, nonpointThem: nonpointThem)
            return
        }
        if iterations > 0 && (us.isPoint() || them.isPoint()) {
            break
        }
        
        if !us.isPoint() {
            nonpointUs = us
        } else if iterations == 0 {
            hadConverged = false
        }
        
        (them, intersects) = bezierClipWithBezierCurve(nonpointThem, curve: nonpointUs, originalCurve: &originalThemData, originalRange: &themRange)
        if !intersects {
            checkNoIntersectionsForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: &us, them: &them, nonpointUs: nonpointUs, nonpointThem: nonpointThem)
            return
        }
        if iterations > 0 && (us.isPoint() || them.isPoint()) {
            break
        }
        
        let percentChangeInUs = (BPRangeGetSize(previousUsRange) - BPRangeGetSize(usRange)) / BPRangeGetSize(previousUsRange)
        let percentChangeInThem = (BPRangeGetSize(previousThemRange) - BPRangeGetSize(themRange)) / BPRangeGetSize(previousThemRange)
        
        var didNotSplit = false
        
        if percentChangeInUs < minimumChangeNeeded && percentChangeInThem < minimumChangeNeeded {
        
            if checkCurvesForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: us, them: them) {
                return
            }
          
            if BPRangeGetSize(usRange) > BPRangeGetSize(themRange) {
                var usRange1 = BPRange(
                    minimum: usRange.minimum,
                    maximum: (usRange.minimum + usRange.maximum) / 2.0)
                let us1 = originalUsData.subcurveWithRange(usRange1)
                var themRangeCopy1 = themRange
                
                var usRange2 = BPRange(
                    minimum: (usRange.minimum + usRange.maximum) / 2.0,
                    maximum: usRange.maximum)
                let us2 = originalUsData.subcurveWithRange(usRange2)
                var themRangeCopy2 = themRange
                
                let range1ConvergedAlready = BPRangeHasConverged(usRange1, decimalPlaces: places) && BPRangeHasConverged(themRange, decimalPlaces: places)
                let range2ConvergedAlready = BPRangeHasConverged(usRange2, decimalPlaces: places) && BPRangeHasConverged(themRange, decimalPlaces: places);
                
                if !range1ConvergedAlready && !range2ConvergedAlready && depth < maxDepth {
                    var leftIntersectRange: BPBezierIntersectRange?
                    pfIntersectionsWithBezierCurve(us1, curve: them, usRange: &usRange1, themRange: &themRangeCopy1, originalUs: originalUs, originalThem: originalThem, intersectRange: &leftIntersectRange, depth: depth + 1, stop: &stop, outputBlock: outputBlock)
                    
                    intersectRange = mergeIntersectRange(intersectRange, otherIntersectRange: leftIntersectRange)
                    
                    if stop {
                        return
                    }
                
                    var rightIntersectRange: BPBezierIntersectRange?
                    pfIntersectionsWithBezierCurve(us2, curve: them, usRange: &usRange2, themRange: &themRangeCopy2, originalUs: originalUs, originalThem: originalThem, intersectRange: &rightIntersectRange, depth: depth + 1, stop: &stop, outputBlock: outputBlock);
                    
                    intersectRange = mergeIntersectRange(intersectRange, otherIntersectRange: rightIntersectRange)
                    return
                } else {
                    didNotSplit = true
                }
            } else {
                var themRange1 = BPRange(
                    minimum: themRange.minimum,
                    maximum: (themRange.minimum + themRange.maximum) / 2.0)
                let them1 = originalThemData.subcurveWithRange(themRange1)
                var usRangeCopy1 = usRange
                
                var themRange2 = BPRange(
                    minimum: (themRange.minimum + themRange.maximum) / 2.0,
                    maximum: themRange.maximum)
                let them2 = originalThemData.subcurveWithRange(themRange2)
                var usRangeCopy2 = usRange
                
                let range1ConvergedAlready = BPRangeHasConverged(themRange1, decimalPlaces: places) && BPRangeHasConverged(usRange, decimalPlaces: places)
                let range2ConvergedAlready = BPRangeHasConverged(themRange2, decimalPlaces: places) && BPRangeHasConverged(usRange, decimalPlaces: places)
                
                if !range1ConvergedAlready && !range2ConvergedAlready && depth < maxDepth {
                    var leftIntersectRange: BPBezierIntersectRange?
                    pfIntersectionsWithBezierCurve(us, curve: them1, usRange: &usRangeCopy1, themRange: &themRange1, originalUs: originalUs, originalThem: originalThem, intersectRange: &leftIntersectRange, depth: depth + 1, stop: &stop, outputBlock: outputBlock)
                    
                    intersectRange = mergeIntersectRange(intersectRange, otherIntersectRange: leftIntersectRange)
                    
                    if stop {
                        return
                    }
                    var rightIntersectRange: BPBezierIntersectRange?
                    pfIntersectionsWithBezierCurve(us, curve: them2, usRange: &usRangeCopy2, themRange: &themRange2, originalUs: originalUs, originalThem: originalThem, intersectRange: &rightIntersectRange, depth: depth + 1, stop: &stop, outputBlock: outputBlock)
                    
                    intersectRange = mergeIntersectRange(intersectRange, otherIntersectRange: rightIntersectRange)
                    
                    return
                } else {
                    didNotSplit = true
                }
            }
            
            if didNotSplit && (BPRangeGetSize(previousUsRange) - BPRangeGetSize(usRange)) == 0 && (BPRangeGetSize(previousThemRange) - BPRangeGetSize(themRange)) == 0 {
                return
            }
        }
        
        iterations += 1
    }
    
    if !BPRangeHasConverged(usRange, decimalPlaces: places) || !BPRangeHasConverged(themRange, decimalPlaces: places) {
        if checkCurvesForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: originalUsData, them: originalThemData) {
            return
        }
        
        refineIntersectionsOverIterations(3, usRange: &usRange, themRange: &themRange, originalUs: &originalUsData, originalThem: &originalThemData, us: &us, them: &them, nonpointUs: &nonpointUs, nonpointThem: &nonpointThem)
        
        if !BPRangeHasConverged(usRange, decimalPlaces: places) || !BPRangeHasConverged(themRange, decimalPlaces: places) {
            refineIntersectionsOverIterations(4, usRange: &usRange, themRange: &themRange, originalUs: &originalUsData, originalThem: &originalThemData, us: &us, them: &them, nonpointUs: &nonpointUs, nonpointThem: &nonpointThem)
        }
    }
    
    if BPRangeHasConverged(usRange, decimalPlaces: places) && !BPRangeHasConverged(themRange, decimalPlaces: places) {
        let intersectionPoint = originalUsData.pointAtParameter(BPRangeAverage(usRange)).point
        
        var refinedParameter = BPRangeAverage(themRange)
        for _ in 0 ..< 3 {
            refinedParameter = pfRefineParameter(originalThemData, parameter: refinedParameter, point: intersectionPoint)
            refinedParameter = min(themRange.maximum, max(themRange.minimum, refinedParameter))
        }
        themRange.minimum = refinedParameter
        themRange.maximum = refinedParameter
        hadConverged = false
    } else if !BPRangeHasConverged(usRange, decimalPlaces: places) && BPRangeHasConverged(themRange, decimalPlaces: places) {
        let intersectionPoint = originalThemData.pointAtParameter(BPRangeAverage(themRange)).point
    
        var refinedParameter = BPRangeAverage(usRange)
        for _ in 0 ..< 3 {
            refinedParameter = pfRefineParameter(originalUsData, parameter: refinedParameter, point: intersectionPoint)
            refinedParameter = min(usRange.maximum, max(usRange.minimum, refinedParameter))
        }
        usRange.minimum = refinedParameter
        usRange.maximum = refinedParameter
        hadConverged = false
    }
    
    if (!BPRangeHasConverged(usRange, decimalPlaces: places) || !BPRangeHasConverged(themRange, decimalPlaces: places)) && iterations >= maxIterations {
        checkForOverlapRange(me, intersectRange: &intersectRange, usRange: &usRange, themRange: &themRange, originalUs: originalUs, originalThem: originalThem, us: us, them: them)
        return
    }
    
    if !hadConverged {
        let intersectionPoint = originalUsData.pointAtParameter(BPRangeAverage(usRange)).point
        let checkPoint = originalThemData.pointAtParameter(BPRangeAverage(themRange)).point
        let threshold = isRunningOn64BitDevice ? 1e-3 : 1e-1
        if !BPArePointsCloseWithOptions(intersectionPoint, point2: checkPoint, threshold: threshold) {
            return
        }
    }
    
    let intersection = BPBezierIntersection(curve1: originalUs, param1: BPRangeAverage(usRange), curve2:originalThem, param2: BPRangeAverage(themRange))
    
    let stopResults = outputBlock(intersection)
    if stopResults.setStop {
        stop = stopResults.stopValue
    }
}

// ========================================================
// MARK: ---- BPBezierCurve ----
// ========================================================


//////////////////////////////////////////////////////////////////////////////////
// BPBezierCurve
//
public func ==(lhs: BPBezierCurve, rhs: BPBezierCurve) -> Bool {
    return dataIsEqual(lhs.data, other: rhs.data)
}

public class BPBezierCurve: CustomDebugStringConvertible, CustomStringConvertible, Equatable {
   
    fileprivate var _startShared = false
    fileprivate var _contour: BPBezierContour?
    fileprivate var _index: Int = 0
    var crossings: [BPEdgeCrossing] = []
    
    var index: Int {
        get {
            return _index
        }
        set {
            _index = newValue
        }
    }

    var isStartShared: Bool {
        return _startShared
    }
    
    var startShared: Bool {
        get {
            return _startShared
        }
        set {
            _startShared = newValue
        }
    }
    
    var contour: BPBezierContour? {
        get {
            return _contour
        }
        set {
            _contour = newValue
        }
    }
   
    fileprivate var _data: BPBezierCurveData
    
    var data: BPBezierCurveData {
        get {
            return _data
        }
    }

    init(endPoint1: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint, endPoint2: CGPoint) {
        _data = BPBezierCurveData(
            endPoint1: endPoint1,
            controlPoint1: controlPoint1,
            controlPoint2: controlPoint2,
            endPoint2: endPoint2,
            isStraightLine: false)
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        let distance = BPDistanceBetweenPoints(startPoint, point2: endPoint)
        let leftTangent = BPNormalizePoint(BPSubtractPoint(endPoint, point2: startPoint))
        
        _data = BPBezierCurveData(
            endPoint1: startPoint,
            controlPoint1: BPAddPoint(startPoint, point2: BPUnitScalePoint(leftTangent, scale: distance / 3.0)),
            controlPoint2: BPAddPoint(startPoint, point2: BPUnitScalePoint(leftTangent, scale: 2.0 * distance / 3.0)),
            endPoint2: endPoint,
            isStraightLine: true)
    }
    
    init(curveData: BPBezierCurveData) {
        _data = curveData;
    }
    
    var endPoint1: CGPoint {
        get {
            return _data.endPoint1
        }
    }
    
    var endPoint2: CGPoint {
        get {
            return _data.endPoint2
        }
    }
    
    var controlPoint1: CGPoint {
        get {
            return _data.controlPoint1
        }
    }
    
    var controlPoint2: CGPoint {
        get {
            return _data.controlPoint2
        }
    }
    
    var isStraightLine: Bool {
        get {
            return _data.isStraightLine
        }
    }
    
    public class func bezierCurvesFromBezierPath(_ path: NSBezierPath!) -> [BPBezierCurve] {
        var startPoint: CGPoint?
        
        let bezier = LRTBezierPathWrapper(path)
        var bezierCurves: [BPBezierCurve] = []
        
        var previousPoint = CGPoint.zero
        
        for item in bezier.elements {
            
            switch item {
            case let .move(v):
                previousPoint = v
                startPoint = v
            case let .line(v):
                bezierCurves.append(BPBezierCurve(startPoint: previousPoint, endPoint: v))
                previousPoint = v
            case .quadCurve(let to, let cp):
                let ⅔: CGFloat = 2.0 / 3.0
                let cp1 = BPAddPoint(previousPoint, point2: BPScalePoint(BPSubtractPoint(cp, point2: previousPoint), scale: ⅔))
                let cp2 = BPAddPoint(to, point2: BPScalePoint(BPSubtractPoint(cp, point2: to), scale: ⅔))
                bezierCurves.append(BPBezierCurve(endPoint1: previousPoint, controlPoint1: cp1, controlPoint2: cp2, endPoint2: to))
                previousPoint = to
            case .cubicCurve(let to, let v1, let v2):
                bezierCurves.append(BPBezierCurve(endPoint1: previousPoint, controlPoint1: v1, controlPoint2: v2, endPoint2: to))
                previousPoint = to
            case .close:
                if let startPoint = startPoint {
                    if !previousPoint.equalTo(startPoint) {
                        bezierCurves.append(BPBezierCurve(startPoint: previousPoint, endPoint: startPoint))
                    }
                }
                startPoint = nil
                previousPoint = CGPoint.zero
            }
        }
        
        return bezierCurves
    }
    
    class func bezierCurveWithLineStartPoint(_ startPoint: CGPoint, endPoint: CGPoint) -> BPBezierCurve {
        return BPBezierCurve(startPoint: startPoint, endPoint: endPoint)
    }
    
    class func bezierCurveWithEndPoint1(_ endPoint1: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint, endPoint2: CGPoint) -> BPBezierCurve {
        return BPBezierCurve(endPoint1: endPoint1, controlPoint1: controlPoint1, controlPoint2: controlPoint2, endPoint2: endPoint2)
    }
    
    class func bezierCurveWithBezierCurveData(_ data: BPBezierCurveData) -> BPBezierCurve {
        return BPBezierCurve(curveData: data)
    }
   
    func isEqual(_ object: AnyObject) -> Bool {
        if let other = object as? BPBezierCurve {
            return dataIsEqual(_data, other: other._data)
        } else {
            return false
        }
    }
    
    func doesHaveIntersectionsWithBezierCurve(_ curve: BPBezierCurve) -> Bool {
        var count = 0
        var unusedRange: BPBezierIntersectRange?
        
        intersectionsWithBezierCurve(curve, overlapRange: &unusedRange) {
            (intersect: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
            count += 1
            return (setStop:true, stopValue:true) // Only need the one
        }
        return count > 0;
    }
    
    public func intersectionsWithBezierCurve(_ curve: BPBezierCurve, overlapRange: inout BPBezierIntersectRange?,
                                             withBlock block: (_ intersect: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool)) {
        if !BPLineBoundsMightOverlap(_data.boundingRect, bounds2: curve._data.boundingRect) {
            return
        }
        if !BPLineBoundsMightOverlap(_data.bounds, bounds2: curve._data.bounds) {
            return
        }
        var usRange = BPRange(minimum: 0, maximum: 1)
        var themRange = BPRange(minimum: 0, maximum: 1)
        var stop = false
        pfIntersectionsWithBezierCurve(_data, curve: curve.data, usRange: &usRange, themRange: &themRange, originalUs: self, originalThem: curve, intersectRange: &overlapRange, depth: 0, stop: &stop, outputBlock: block)
    }

    func subcurveWithRange(_ range: BPRange) -> BPBezierCurve {
        return BPBezierCurve(curveData: _data.subcurveWithRange(range))
    }

    func splitSubcurvesWithRange(_ range: BPRange, left: Bool, middle: Bool, right: Bool) -> (left: BPBezierCurve?, mid: BPBezierCurve?, right: BPBezierCurve?) {
        var leftResult: BPBezierCurve?
        var midResult: BPBezierCurve?
        var rightResult: BPBezierCurve?
    
        var remainingCurve: BPBezierCurveData?
        if range.minimum == 0.0 {
            remainingCurve = _data
        } else {
            var leftCurveData: BPBezierCurveData?
            let pap = _data.pointAtParameter(range.minimum)
            leftCurveData = pap.leftCurve
            remainingCurve = pap.rightCurve
            if left {
                if let leftCurveData = leftCurveData {
                    leftResult = BPBezierCurve(curveData: leftCurveData)
                }
            }
        }
        if range.minimum == 1.0 {
            if middle {
                if let remainingCurve = remainingCurve {
                    midResult = BPBezierCurve(curveData: remainingCurve)
                }
            }
        } else if let remainingCurve = remainingCurve {
            let adjustedMaximum = (range.maximum - range.minimum) / (1.0 - range.minimum)
            let pap = remainingCurve.pointAtParameter(adjustedMaximum)
            if middle {
                if let curveData = pap.leftCurve {
                    midResult = BPBezierCurve(curveData: curveData)
                }
            }
            if right {
                if let curveData = pap.rightCurve {
                    rightResult = BPBezierCurve(curveData: curveData)
                }
            }
        }
        return (left: leftResult, mid: midResult, right: rightResult)
    }
    
    func reversedCurve() -> BPBezierCurve {
        return BPBezierCurve(curveData: reversed(_data))
    }
    
    func pointAtParameter(_ parameter: Double) -> (point: CGPoint, leftBezierCurve: BPBezierCurve?, rightBezierCurve: BPBezierCurve?) {
        var leftBezierCurve: BPBezierCurve?
        var rightBezierCurve: BPBezierCurve?
        
        let pap = _data.pointAtParameter(parameter)
        if let leftData = pap.leftCurve {
            leftBezierCurve = BPBezierCurve(curveData: leftData)
        }
        if let rightData = pap.rightCurve {
            rightBezierCurve = BPBezierCurve(curveData: rightData)
        }
        return (point: pap.point, leftBezierCurve: leftBezierCurve, rightBezierCurve: rightBezierCurve)
    }
  
    fileprivate func refineParameter(_ parameter: Double, forPoint point: CGPoint) -> Double {
        return pfRefineParameter(self.data, parameter: parameter, point: point)
    }
    
    func length() -> Double {
        return _data.getLength()
    }
    
    func lengthAtParameter(_ parameter: Double) -> Double {
        return _data.getLengthAtParameter(parameter)
    }

    var isPoint: Bool {
        return _data.isPoint()
    }
    func closestLocationToPoint(_ point: CGPoint) -> BPBezierCurveLocation {
        return _data.closestLocationToPoint(point)
    }
    
    var bounds: CGRect {
        return _data.bounds
    }
    
    var boundingRect: CGRect {
        return _data.boundingRect
    }
   
    func pointFromRightOffset(_ offset: Double) -> CGPoint {
        var offset = offset
        let len = length()
        offset = min(offset, len)
        let time = 1.0 - (offset / len)
        return _data.pointAtParameter(time).point
    }
   
    func pointFromLeftOffset(_ offset: Double) -> CGPoint {
        var offset = offset
        let len = length()
        offset = min(offset, len)
        let time = offset / len
        return _data.pointAtParameter(time).point
    }
    
    func tangentFromRightOffset(_ offset: Double) -> CGPoint {
        var offset = offset
        if _data.isStraightLine && !_data.isPoint() {
            return BPSubtractPoint(_data.endPoint1, point2: _data.endPoint2)
        }
        
        if offset == 0.0 && !_data.controlPoint2.equalTo(_data.endPoint2) {
            return BPSubtractPoint(_data.controlPoint2, point2: _data.endPoint2)
        } else {
            let len = length()
            if offset == 0.0 {
                offset = min(1.0, len)
            }
            let time = 1.0 - (offset / len)
            let pap = _data.pointAtParameter(time)
            if let curve = pap.leftCurve {
                return BPSubtractPoint(curve.controlPoint2, point2: curve.endPoint2)
            }
        }
        return CGPoint.zero
    }
   
    func tangentFromLeftOffset(_ offset: Double) -> CGPoint {
        var offset = offset
        if _data.isStraightLine && !_data.isPoint() {
            return BPSubtractPoint(_data.endPoint2, point2: _data.endPoint1)
        }
        
        if offset == 0.0 && !_data.controlPoint1.equalTo(_data.endPoint1) {
            return BPSubtractPoint(_data.controlPoint1, point2: _data.endPoint1)
        } else {
            let len = length()
            if offset == 0.0 {
                offset = min(1.0, len)
            }
            let time = offset / len
            let pap = _data.pointAtParameter(time)
            if let curve = pap.rightCurve {
                return BPSubtractPoint(curve.controlPoint2, point2: curve.endPoint2)
            }
        }
        return CGPoint.zero
    }
   
    var bezierPath: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: endPoint1)
        path.curve(to: endPoint2, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        return path
    }
    
    func clone() -> BPBezierCurve {
        return BPBezierCurve(curveData: _data)
    }
    
    public var description: String {
        return "<\(_data.endPoint1.x), \(_data.endPoint1.y), \(_data.controlPoint1.x), \(_data.controlPoint1.y), \(_data.controlPoint2.x), \(_data.controlPoint2.y), \(_data.endPoint2.x), \(_data.endPoint2.y)>"
    }
    
    public var debugDescription: String {
        return String(format: "<BPBezierCurve (%.18f, %.18f)-[%.18f, %.18f] curve to [%.18f, %.18f]-(%.18f, %.18f)>",
                      _data.endPoint1.x, _data.endPoint1.y, _data.controlPoint1.x, _data.controlPoint1.y,
                      _data.controlPoint2.x, _data.controlPoint2.y, _data.endPoint2.x, _data.endPoint2.y)
    }
    
}


