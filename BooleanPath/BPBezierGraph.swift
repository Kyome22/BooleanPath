//
//  BPBezierGraph.swift
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

class BPBezierGraph {
    
    fileprivate var _bounds: CGRect
    fileprivate var _contours: [BPBezierContour]
    
    var contours: [BPBezierContour] {
        get {
            return _contours
        }
    }
    
    init() {
        _contours = []
        _bounds = CGRect.null
    }
    
    init(path: NSBezierPath) {
        _contours = []
        _bounds = CGRect.null
        _ = initWithBezierPath(path)
    }
    
    class func bezierGraphWithBezierPath(_ path: NSBezierPath!) -> AnyObject {
        return BPBezierGraph().initWithBezierPath(path)
    }
    
    func initWithBezierPath(_ path: NSBezierPath!) -> BPBezierGraph {
        var lastPoint: CGPoint = CGPoint.zero
        var wasClosed = false
        
        var contour: BPBezierContour?
        let bezier = LRTBezierPathWrapper(path)
        
        for (_, elem) in bezier.elements.enumerated() {
            switch elem {
            case let .move(toPt):
                if !wasClosed && contour != nil {
                    contour?.close()
                }
                wasClosed = false
                contour = BPBezierContour()
                addContour(contour!)
                lastPoint = toPt
            case .line(let toPt):
                if !toPt.equalTo(lastPoint) {
                    if let contour = contour {
                        contour.addCurve(BPBezierCurve.bezierCurveWithLineStartPoint(lastPoint, endPoint:toPt))
                    }
                    lastPoint = toPt
                }
            case .quadCurve(let toPt, let via):
                let allPointsEqual = toPt.equalTo(lastPoint)
                    && toPt.equalTo(via)
                if !allPointsEqual {
                    let ⅔: CGFloat = 2.0 / 3.0
                    let cp1 = BPAddPoint(lastPoint, point2: BPScalePoint(BPSubtractPoint(via, point2: lastPoint), scale: ⅔))
                    let cp2 = BPAddPoint(toPt, point2: BPScalePoint(BPSubtractPoint(via, point2: toPt), scale: ⅔))
                    
                    contour?.addCurve(BPBezierCurve(endPoint1: lastPoint, controlPoint1: cp1, controlPoint2: cp2, endPoint2: toPt))
                    lastPoint = toPt
                }
            case .cubicCurve(let toPt, let v1, let v2):
                let allPointsEqual = toPt.equalTo(lastPoint)
                    && toPt.equalTo(v1)
                    && toPt.equalTo(v2)
                if !allPointsEqual {
                    contour?.addCurve(BPBezierCurve(endPoint1: lastPoint, controlPoint1: v1, controlPoint2: v2, endPoint2: toPt))
                    lastPoint = toPt
                }
            case .close:
                if let contour = contour {
                    let edges = contour.edges
                    if edges.count > 0 {
                        let firstEdge = edges[0]
                        let firstPoint = firstEdge.endPoint1
                        
                        if !lastPoint.equalTo(firstPoint) {
                            contour.addCurve(BPBezierCurve.bezierCurveWithLineStartPoint(lastPoint, endPoint:firstPoint))
                            wasClosed = true
                        }
                    }
                }
                lastPoint = CGPoint.zero
            }
        }
        return self
    }
    
    func union(with graph: BPBezierGraph) -> BPBezierGraph {
        insertCrossingsWithBezierGraph(graph)
        insertSelfCrossings()
        graph.insertSelfCrossings()
        cleanupCrossingsWithBezierGraph(graph)
        self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
        graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: false)
        
        var result = bezierGraphFromIntersections

        unionNonintersectingPartsIntoGraph(&result, withGraph: graph)
        self.removeCrossings()
        graph.removeCrossings()
        self.removeOverlaps()
        graph.removeOverlaps()
        
        return result
    }

    fileprivate func unionNonintersectingPartsIntoGraph(_ result: inout BPBezierGraph, withGraph graph: BPBezierGraph) {

        var ourNonintersectingContours = self.nonintersectingContours
        var theirNonintersectinContours = graph.nonintersectingContours
        var finalNonintersectingContours = ourNonintersectingContours

        finalNonintersectingContours += theirNonintersectinContours
        unionEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours, results: &finalNonintersectingContours)

        for ourContour in ourNonintersectingContours {
            let clipContainsSubject = graph.containsContour(ourContour)
            if clipContainsSubject {
                for (index, element) in finalNonintersectingContours.enumerated() {
                    if element === ourContour {
                        finalNonintersectingContours.remove(at: index)
                        break
                    }
                }
            }
        }
        
        for theirContour in theirNonintersectinContours {
            let subjectContainsClip = self.containsContour(theirContour)
            if subjectContainsClip {
                for (index, element) in finalNonintersectingContours.enumerated() {
                    if element === theirContour {
                        finalNonintersectingContours.remove(at: index)
                        break
                    }
                }
            }
        }
        
        for contour in finalNonintersectingContours {
            result.addContour(contour)
        }
    }
 
    fileprivate func unionEquivalentNonintersectingContours(_ ourNonintersectingContours: inout [BPBezierContour], withContours theirNonintersectingContours: inout [BPBezierContour], results: inout [BPBezierContour]) {
        
        var ourIndex = 0
        while ourIndex < ourNonintersectingContours.count {
            let ourContour = ourNonintersectingContours[ourIndex]
            for theirIndex in 0 ..< theirNonintersectingContours.count  {
                let theirContour = theirNonintersectingContours[theirIndex]
                
                if !ourContour.isEquivalent(theirContour) {
                    continue
                }
                if ourContour.inside == theirContour.inside  {
                    for (index, element) in results.enumerated() {
                        if element === theirContour {
                            results.remove(at: index)
                            break
                        }
                    }
                } else {
                    for (index, element) in results.enumerated() {
                        if element === theirContour {
                            results.remove(at: index)
                            break
                        }
                    }
                    for (index, element) in results.enumerated() {
                        if element === ourContour {
                            results.remove(at: index)
                            break
                        }
                    }
                }
                theirNonintersectingContours.remove(at: theirIndex)
                ourNonintersectingContours.remove(at: ourIndex)
                ourIndex -= 1
                break
            }
            ourIndex += 1
        }
    }
    
    func intersect(with graph: BPBezierGraph) -> BPBezierGraph {
        insertCrossingsWithBezierGraph(graph)
        self.insertSelfCrossings()
        graph.insertSelfCrossings()
        cleanupCrossingsWithBezierGraph(graph)
     
        self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: true)
        graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: true)
        
        var result = bezierGraphFromIntersections

        intersectNonintersectingPartsIntoGraph(&result, withGraph: graph)

        self.removeCrossings()
        graph.removeCrossings()
        self.removeOverlaps()
        graph.removeOverlaps()
        
        return result
    }
    
    fileprivate func intersectNonintersectingPartsIntoGraph(_ result: inout BPBezierGraph, withGraph graph: BPBezierGraph) {
        var ourNonintersectingContours = self.nonintersectingContours
        var theirNonintersectinContours = graph.nonintersectingContours
        var finalNonintersectingContours = intersectEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours)
        
        for ourContour in ourNonintersectingContours {
            let clipContainsSubject = graph.containsContour(ourContour)
            if clipContainsSubject {
                finalNonintersectingContours.append(ourContour)
            }
        }
        for theirContour in theirNonintersectinContours {
            let subjectContainsClip = self.containsContour(theirContour)
            if subjectContainsClip {
                finalNonintersectingContours.append(theirContour)
            }
        }
        for contour in finalNonintersectingContours {
            result.addContour(contour)
        }
    }

    fileprivate func intersectEquivalentNonintersectingContours(_ ourNonintersectingContours: inout [BPBezierContour], withContours theirNonintersectingContours: inout [BPBezierContour]) -> [BPBezierContour] {
        
        var results: [BPBezierContour] = []
        
        var ourIndex = 0
        while ourIndex < ourNonintersectingContours.count {
            let ourContour = ourNonintersectingContours[ourIndex]
            for theirIndex in 0 ..< theirNonintersectingContours.count {
                let theirContour = theirNonintersectingContours[theirIndex]
                
                if !ourContour.isEquivalent(theirContour) {
                    continue
                }
                
                if ourContour.inside == theirContour.inside {
                    results.append(ourContour)
                } else {
                    if theirContour.inside == .hole {
                        results.append(theirContour)
                    } else {
                        results.append(ourContour)
                    }
                }
             
                theirNonintersectingContours.remove(at: theirIndex)
                ourNonintersectingContours.remove(at: ourIndex)
                ourIndex -= 1
                break
            }
            ourIndex += 1
        }
        return results
    }
   
    func subtract(with graph: BPBezierGraph) -> BPBezierGraph {
      
        insertCrossingsWithBezierGraph(graph)
        self.insertSelfCrossings()
        graph.insertSelfCrossings()
        cleanupCrossingsWithBezierGraph(graph)
       
        self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
        graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: true)
        
        let result = bezierGraphFromIntersections
        
        var ourNonintersectingContours = self.nonintersectingContours
        var theirNonintersectinContours = graph.nonintersectingContours
        var finalNonintersectingContours = subtractEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours)
        
        for ourContour in ourNonintersectingContours {
            let clipContainsSubject = graph.containsContour(ourContour)
            if !clipContainsSubject {
                finalNonintersectingContours.append(ourContour)
            }
        }
        for theirContour in theirNonintersectinContours {
            let subjectContainsClip = self.containsContour(theirContour)
            if subjectContainsClip {
                finalNonintersectingContours.append(theirContour)   // add it as a hole
            }
        }

        for contour in finalNonintersectingContours {
            result.addContour(contour)
        }
        
        self.removeCrossings()
        graph.removeCrossings()
        self.removeOverlaps()
        graph.removeOverlaps()
        
        return result
    }
    
    fileprivate func subtractEquivalentNonintersectingContours(_ ourNonintersectingContours: inout [BPBezierContour], withContours theirNonintersectingContours: inout [BPBezierContour]) -> [BPBezierContour] {
        
        var results: [BPBezierContour] = []
        
        var ourIndex = 0
        while ourIndex < ourNonintersectingContours.count {
            let ourContour = ourNonintersectingContours[ourIndex]
            for theirIndex in 0 ..< theirNonintersectingContours.count {
                let theirContour = theirNonintersectingContours[theirIndex]
                if !ourContour.isEquivalent(theirContour) {
                    continue
                }
                
                if ourContour.inside != theirContour.inside {
                    results.append(ourContour)
                } else if ourContour.inside == .hole && theirContour.inside == .hole {
                    results.append(ourContour)
                }
                theirNonintersectingContours.remove(at: theirIndex)
                ourNonintersectingContours.remove(at: ourIndex)
                ourIndex -= 1
                break
            }
            ourIndex += 1
        }
        return results
    }

    internal func markCrossingsAsEntryOrExitWithBezierGraph(_ otherGraph: BPBezierGraph, markInside: Bool) {
        for contour in contours {
            let intersectingContours = contour.intersectingContours
            for otherContour in intersectingContours {
                if otherContour.inside == .hole {
                    contour.markCrossingsAsEntryOrExitWithContour(otherContour, markInside: !markInside)
                } else {
                    contour.markCrossingsAsEntryOrExitWithContour(otherContour, markInside: markInside)
                }
            }
        }
    }
    
    // don't use this function
    func difference(with graph: BPBezierGraph) -> BPBezierGraph {
        insertCrossingsWithBezierGraph(graph)
        insertSelfCrossings()
        graph.insertSelfCrossings()
        cleanupCrossingsWithBezierGraph(graph)

        self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
        graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: false)
      
        var allParts = bezierGraphFromIntersections
        unionNonintersectingPartsIntoGraph(&allParts, withGraph:graph)
        
        self.markAllCrossingsAsUnprocessed()
        graph.markAllCrossingsAsUnprocessed()
      
        self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside:true)
        graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside:true)
        
        var intersectingParts = bezierGraphFromIntersections
        intersectNonintersectingPartsIntoGraph(&intersectingParts, withGraph: graph)
      
        self.removeCrossings()
        graph.removeCrossings()
        self.removeOverlaps()
        graph.removeOverlaps()
        
        return allParts.subtract(with: intersectingParts)
    }
    
    var bezierPath: NSBezierPath {
        let path = NSBezierPath()
        path.windingRule = NSBezierPath.WindingRule.evenOdd
        
        for contour in _contours {
            var firstPoint = true
            for edge in contour.edges {
                if firstPoint {
                    path.move(to: edge.endPoint1)
                    firstPoint = false
                }
                
                if edge.isStraightLine {
                    path.line(to: edge.endPoint2)
                } else {
                    path.curve(to: edge.endPoint2, controlPoint1: edge.controlPoint1, controlPoint2: edge.controlPoint2)
                }
            }
            if !path.isEmpty {
                path.close()
            }
        }
        return path
    }
 
    internal func insertCrossingsWithBezierGraph(_ other: BPBezierGraph) {
       
        for ourContour in contours {
            for theirContour in other.contours {
                let overlap = BPContourOverlap()
                for ourEdge in ourContour.edges {
                    for theirEdge in theirContour.edges {
                        var intersectRange: BPBezierIntersectRange?
                        ourEdge.intersectionsWithBezierCurve(theirEdge, overlapRange: &intersectRange) {
                            (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                            if intersection.isAtStartOfCurve1 {
                                ourEdge.startShared = true
                            }
                            if intersection.isAtStopOfCurve1 {
                                ourEdge.next.startShared = true
                            }
                            if intersection.isAtStartOfCurve2 {
                                theirEdge.startShared = true
                            }
                            if intersection.isAtStopOfCurve2 {
                                theirEdge.next.startShared = true
                            }
                            if !ourEdge.crossesEdge(theirEdge, atIntersection: intersection) {
                                return (false, false)
                            }
                            let ourCrossing = BPEdgeCrossing(intersection: intersection)
                            let theirCrossing = BPEdgeCrossing(intersection: intersection)
                            ourCrossing.counterpart = theirCrossing
                            theirCrossing.counterpart = ourCrossing
                            ourEdge.addCrossing(ourCrossing)
                            theirEdge.addCrossing(theirCrossing)
                            return (false, false)
                        }
                        
                        if let intersectRange = intersectRange {
                            overlap.addOverlap(intersectRange, forEdge1: ourEdge, edge2: theirEdge)
                        }
                    }
                }
               
                if !overlap.isComplete {
                    overlap.runsWithBlock() {
                        (run: BPEdgeOverlapRun) -> Bool in
                        if run.isCrossing {
                            run.addCrossings()
                        }
                        return false
                    }
                }
                
                ourContour.addOverlap(overlap)
                theirContour.addOverlap(overlap)
            }
        }
    }
    
    func cleanupCrossingsWithBezierGraph(_ other: BPBezierGraph) {
        removeDuplicateCrossings()
        other.removeDuplicateCrossings()
        removeCrossingsInOverlaps()
        other.removeCrossingsInOverlaps()
    }
    
    func removeCrossingsInOverlaps() {
        for ourContour in contours {
            for ourEdge in ourContour.edges {
                ourEdge.crossingsCopyWithBlock() {
                    (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
                    if crossing.fromCrossingOverlap {
                        return (false, false)
                    }
                    
                    if ourContour.doesOverlapContainCrossing(crossing) {
                        let counterpart = crossing.counterpart
                        crossing.removeFromEdge()
                        if let counterpart = counterpart {
                            counterpart.removeFromEdge()
                        }
                    }
                    return (false, false)
                }
                
            }
        }
    }

    fileprivate func removeDuplicateCrossings() {
        for ourContour in contours {
            for ourEdge in ourContour.edges {
                
                ourEdge.crossingsCopyWithBlock() {
                    (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
                    
                    if let crossingEdge = crossing.edge, let lastCrossing = crossingEdge.previous.lastCrossing {
                        if crossing.isAtStart && lastCrossing.isAtEnd {
                            let counterpart = crossing.counterpart
                            crossing.removeFromEdge()
                            if let counterpart = counterpart {
                                counterpart.removeFromEdge()
                            }
                        }
                    }
                    
                    if let crossingEdge = crossing.edge, let firstCrossing = crossingEdge.next.firstCrossing {
                        if crossing.isAtEnd && firstCrossing.isAtStart {
                            let counterpart = firstCrossing.counterpart
                            firstCrossing.removeFromEdge()
                            if let counterpart = counterpart {
                                counterpart.removeFromEdge()
                            }
                        }
                    }
                    return (false, false)
                }
            }
        }
    }
    
    internal func insertSelfCrossings() {
        var remainingContours = self.contours
        
        while remainingContours.count > 0 {
            if let firstContour = remainingContours.last {
                for secondContour in remainingContours {
                    if firstContour === secondContour {
                        continue
                    }
                    if !BPLineBoundsMightOverlap(firstContour.boundingRect, bounds2: secondContour.boundingRect)
                        || !BPLineBoundsMightOverlap(firstContour.bounds, bounds2: secondContour.bounds) {
                        continue
                    }
                    for firstEdge in firstContour.edges {
                        for secondEdge in secondContour.edges {
                            var unused: BPBezierIntersectRange?
                            firstEdge.intersectionsWithBezierCurve(secondEdge, overlapRange: &unused) {
                                (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                                if intersection.isAtStartOfCurve1 {
                                    firstEdge.startShared = true
                                } else if intersection.isAtStopOfCurve1 {
                                    firstEdge.next.startShared = true
                                }
                                if intersection.isAtStartOfCurve2 {
                                    secondEdge.startShared = true
                                } else if intersection.isAtStopOfCurve2 {
                                    secondEdge.next.startShared = true
                                }
                                if !firstEdge.crossesEdge(secondEdge, atIntersection: intersection) {
                                    return (false, false)
                                }
                                
                                let firstCrossing = BPEdgeCrossing(intersection: intersection)
                                let secondCrossing = BPEdgeCrossing(intersection: intersection)
                                
                                firstCrossing.selfCrossing = true
                                secondCrossing.selfCrossing = true
                                firstCrossing.counterpart = secondCrossing
                                secondCrossing.counterpart = firstCrossing
                                firstEdge.addCrossing(firstCrossing)
                                secondEdge.addCrossing(secondCrossing)
                                
                                return (false, false)
                            }
                        }
                    }
                }
            }
            remainingContours.removeLast()
        }
        for contour in _contours {
            if contour.edges.count == 0 {
                continue
            }
            contour.inside = contourInsides(contour)
        }
    }
 
    var bounds: CGRect {
        if !_bounds.equalTo(CGRect.null) {
            return _bounds
        }
        if _contours.count == 0 {
            return CGRect.zero
        }
        for contour in _contours {
            _bounds = _bounds.union(contour.bounds)
        }
        return _bounds
    }
   
    fileprivate func contourInsides(_ testContour: BPBezierContour) -> BPContourInside {
        let testPoint = testContour.testPointForContainment
    
        let beyondX = testPoint.x > self.bounds.minX ? self.bounds.minX - 10 : self.bounds.maxX + 10
        let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y)
        let testCurve = BPBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)
        
        var intersectCount = 0
        for contour in contours {
            if contour.edges.count == 0 {
                continue
            }
            if contour === testContour || contour.crossesOwnContour(testContour) {
                continue
            }
            intersectCount += contour.numberOfIntersectionsWithRay(testCurve)
        }
       
        if intersectCount.isOdd {
            return .hole
        } else {
            return .filled
        }
    }
    
    func closestLocationToPoint(_ point: CGPoint) -> BPCurveLocation? {
        var closestLocation: BPCurveLocation? = nil
        
        for contour in _contours {
            let contourLocation: BPCurveLocation? = contour.closestLocationToPoint(point)
            if ( contourLocation != nil && (closestLocation == nil || contourLocation!.distance < closestLocation!.distance) ) {
                closestLocation = contourLocation
            }
        }
        if let closestLocation = closestLocation {
            closestLocation.graph = self
            return closestLocation
        } else {
            return nil
        }
    }
    
    func debugPathForContainmentOfContour(_ testContour: BPBezierContour) -> NSBezierPath {
        return debugPathForContainmentOfContour(testContour, transform: AffineTransform.identity)
    }
    
    func debugPathForContainmentOfContour(_ testContour: BPBezierContour, transform: AffineTransform) -> NSBezierPath {
        let path = NSBezierPath()
        
        var intersectCount = 0
        for contour in self.contours {
            if contour === testContour {
                continue
            }
            var intersectsWithThisContour = false
            
            for edge in contour.edges {
                for oneTestEdge in testContour.edges {
                    var unusedRange: BPBezierIntersectRange?
                    oneTestEdge.intersectionsWithBezierCurve(edge, overlapRange: &unusedRange) {
                        (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                        
                        if intersection.isAtStartOfCurve1 {
                            oneTestEdge.startShared = true
                        } else if intersection.isAtStopOfCurve1 {
                            oneTestEdge.next.startShared = true
                        }
                        
                        if intersection.isAtStartOfCurve2 {
                            edge.startShared = true
                        } else if intersection.isAtStopOfCurve2 {
                            edge.next.startShared = true
                        }
                        
                        if oneTestEdge.crossesEdge(edge, atIntersection: intersection) {
                            intersectsWithThisContour = true
                        }
                        
                        return (false, false)
                    }
                }
            }
            if intersectsWithThisContour {
                continue
            }
        
            let testPoint = testContour.testPointForContainment
            
            let beyondX = testPoint.x > self.bounds.minX ? self.bounds.minX - 10 : self.bounds.maxX + 10
            let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y)
            let testCurve = BPBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)
            contour.intersectionsWithRay(testCurve, withBlock: {
                (intersection: BPBezierIntersection) -> Void in
                intersectCount += 1
            })
        }
        
        let testPoint = testContour.testPointForContainment
    
        let beyondX = testPoint.x > self.bounds.minX ? self.bounds.minX - 10 : self.bounds.maxX + 10
        let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y);
        let testCurve = BPBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)
        
        let curvePath = testCurve.bezierPath
        curvePath.transform(using: transform)
        path.append(curvePath)
        
        if intersectCount.isOdd {
            let dashes: [CGFloat] = [CGFloat(2), CGFloat(3)]
            path.setLineDash(dashes, count: 2, phase: 0)
        }
        
        return path
    }
    
    func debugPathForJointsOfContour(_ testContour: BPBezierContour) -> NSBezierPath {
        let path = NSBezierPath()
        
        for edge in testContour.edges {
            if !edge.isStraightLine {
                path.move(to: edge.endPoint1)
                path.line(to: edge.controlPoint1)
                path.append(NSBezierPath.smallCircleAtPoint(edge.controlPoint1))
                path.move(to: edge.endPoint2)
                path.line(to: edge.controlPoint2)
                path.append(NSBezierPath.smallCircleAtPoint(edge.controlPoint2))
            }
            path.append(NSBezierPath.smallRectAtPoint(edge.endPoint2))
        }
        
        return path
    }

    fileprivate func containsContour(_ testContour: BPBezierContour) -> Bool {
        let BPRayOverlap = CGFloat(10.0)
        if !BPLineBoundsMightOverlap(self.bounds, bounds2: testContour.bounds) {
            return false
        }
       
        var containers: [BPBezierContour] = self._contours
        
        let count = Int(max(ceil(testContour.bounds.width), ceil(testContour.bounds.height)))
        guard count > 0 else { return false }
        for fraction in 2 ... count * 2 {
            var didEliminate = false
        
            let verticalSpacing = (testContour.bounds.height) / CGFloat(fraction)
            let yStart = testContour.bounds.minY + verticalSpacing
            let yFinir = testContour.bounds.maxY
            var y = yStart
            while y < yFinir {
                let rayStart = CGPoint(x: min(self.bounds.minX, testContour.bounds.minX) - BPRayOverlap, y: y)
                let rayFinir = CGPoint(x: max(self.bounds.maxX, testContour.bounds.maxX) + BPRayOverlap, y: y)
                let ray = BPBezierCurve(startPoint: rayStart, endPoint: rayFinir)
            
                let eliminated = eliminateContainers(&containers, thatDontContainContour: testContour, usingRay: ray)
                if eliminated {
                    didEliminate = true
                }
                y += verticalSpacing
            }
            
            let horizontalSpacing = (testContour.bounds.width) / CGFloat(fraction)
            let xStart = testContour.bounds.minX + horizontalSpacing
            let xFinir = testContour.bounds.maxX
            var x = xStart
            while x < xFinir {
                let rayStart = CGPoint(x: x, y: min(self.bounds.minY, testContour.bounds.minY) - BPRayOverlap)
                let rayFinir = CGPoint(x: x, y: max(self.bounds.maxY, testContour.bounds.maxY) + BPRayOverlap)
                let ray = BPBezierCurve(startPoint: rayStart, endPoint: rayFinir)
                
                let eliminated = eliminateContainers(&containers, thatDontContainContour: testContour, usingRay: ray)
                if eliminated {
                    didEliminate = true
                }
                x += horizontalSpacing
            }
        
            if containers.count == 0 {
                return false
            }
         
            if didEliminate {
                return containers.count.isOdd
            }
        }
        return false
    }
    
    fileprivate func findBoundsOfContour(_ testContour: BPBezierContour,
                                         onRay ray: BPBezierCurve,
                                         minimum testMinimum: inout CGPoint,
                                         maximum testMaximum: inout CGPoint) -> Bool {
        
        let horizontalRay = ray.endPoint1.y == ray.endPoint2.y
        
        var rayIntersections: [BPBezierIntersection] = []
        var unusedRange: BPBezierIntersectRange?
        for edge in testContour.edges {
            ray.intersectionsWithBezierCurve(edge, overlapRange: &unusedRange) {
                (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                
                rayIntersections.append(intersection)
                return (false, false)
            }
        }
        if rayIntersections.count == 0 {
            return false
        }

        let firstRayIntersection = rayIntersections[0]
        testMinimum = firstRayIntersection.location
        testMaximum = testMinimum
        for intersection in rayIntersections {
            if ( horizontalRay ) {
                if intersection.location.x < testMinimum.x {
                    testMinimum = intersection.location
                }
                if intersection.location.x > testMaximum.x {
                    testMaximum = intersection.location
                }
            } else {
                if intersection.location.y < testMinimum.y {
                    testMinimum = intersection.location
                }
                if intersection.location.y > testMaximum.y {
                    testMaximum = intersection.location
                }
            }
        }
        return true
    }
    
    fileprivate func findCrossingsOnContainers(_ containers: [BPBezierContour], onRay ray: BPBezierCurve, beforeMinimum testMinimum: CGPoint, afterMaximum testMaximum: CGPoint, crossingsBefore crossingsBeforeMinimum: inout [BPEdgeCrossing], crossingsAfter crossingsAfterMaximum: inout [BPEdgeCrossing]) -> Bool {
        
        let horizontalRay = ray.endPoint1.y == ray.endPoint2.y
        
        var ambiguousCrossings: [BPEdgeCrossing] = []
        for container in containers {
            for containerEdge in container.edges {
                var ambigious = false
                var unusedRange: BPBezierIntersectRange?
                
                ray.intersectionsWithBezierCurve(containerEdge, overlapRange: &unusedRange) {
                    (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                    
                    if intersection.isTangent {
                        return (false, false)
                    }
                   
                    if intersection.isAtEndPointOfCurve2 {
                        ambigious = true
                        return (true, true)
                    }
                    
                    if horizontalRay && BPIsValueLessThan(intersection.location.x, maximum: testMaximum.x) && BPIsValueGreaterThan(intersection.location.x, minimum: testMinimum.x) {
                        return (false, false)
                    } else if !horizontalRay && BPIsValueLessThan(intersection.location.y, maximum: testMaximum.y) && BPIsValueGreaterThan(intersection.location.y, minimum: testMinimum.y) {
                        return (false, false)
                    }
                    
                    let crossing = BPEdgeCrossing(intersection: intersection)
                    crossing.edge = containerEdge
                    
                    if testMaximum.equalTo(testMinimum) && testMaximum.equalTo(intersection.location) {
                        ambiguousCrossings.append(crossing)
                        return (false, false)
                    }
                    
                    if horizontalRay && BPIsValueLessThanEqual(intersection.location.x, maximum: testMinimum.x) {
                        crossingsBeforeMinimum.append(crossing)
                    } else if !horizontalRay && BPIsValueLessThanEqual(intersection.location.y, maximum: testMinimum.y) {
                        crossingsBeforeMinimum.append(crossing)
                    }
                    if horizontalRay && BPIsValueGreaterThanEqual(intersection.location.x, minimum: testMaximum.x) {
                        crossingsAfterMaximum.append(crossing)
                    } else if !horizontalRay && BPIsValueGreaterThanEqual(intersection.location.y, minimum: testMaximum.y) {
                        crossingsAfterMaximum.append(crossing)
                    }
                    return (false, false)
                }
                
                if ambigious {
                    return false
                }
            }
        }
        
        for ambiguousCrossing in ambiguousCrossings {
            if let ambigEdge = ambiguousCrossing.edge, let edgeContour = ambigEdge.contour {
                let numberOfTimesContourAppearsBefore = numberOfTimesContour(edgeContour, appearsInCrossings: crossingsBeforeMinimum)
                let numberOfTimesContourAppearsAfter = numberOfTimesContour(edgeContour, appearsInCrossings:crossingsAfterMaximum)
                if numberOfTimesContourAppearsBefore < numberOfTimesContourAppearsAfter {
                    crossingsBeforeMinimum.append(ambiguousCrossing)
                } else {
                    crossingsAfterMaximum.append(ambiguousCrossing)
                }
            }
        }
        return true
    }
    
    fileprivate func numberOfTimesContour(_ contour: BPBezierContour, appearsInCrossings crossings: [BPEdgeCrossing]) -> Int {
        var count = 0
        for crossing in crossings {
            if let crossingEdge = crossing.edge {
                if crossingEdge.contour === contour {
                    count += 1
                }
            }
        }
        return count
    }

    fileprivate func eliminateContainers(_ containers: inout [BPBezierContour], thatDontContainContour testContour: BPBezierContour, usingRay ray: BPBezierCurve) -> Bool {
       
        var testMinimum = CGPoint.zero
        var testMaximum = CGPoint.zero
        let foundBounds = findBoundsOfContour(testContour, onRay: ray, minimum: &testMinimum, maximum: &testMaximum)
        
        if !foundBounds {
            return false
        }
        
        var crossingsBeforeMinimum: [BPEdgeCrossing] = []
        var crossingsAfterMaximum: [BPEdgeCrossing] = []
        let foundCrossings = findCrossingsOnContainers(containers, onRay: ray, beforeMinimum: testMinimum, afterMaximum: testMaximum, crossingsBefore: &crossingsBeforeMinimum, crossingsAfter:&crossingsAfterMaximum)
        
        if !foundCrossings {
            return false
        }
        
        removeContoursThatDontContain(&crossingsBeforeMinimum)
        removeContoursThatDontContain(&crossingsAfterMaximum)
        
        removeContourCrossings(&crossingsBeforeMinimum, thatDontAppearIn: crossingsAfterMaximum)
        removeContourCrossings(&crossingsAfterMaximum, thatDontAppearIn: crossingsBeforeMinimum)
        
        containers = contoursFromCrossings(crossingsBeforeMinimum)
        
        return true
    }
    
    fileprivate func contoursFromCrossings(_ crossings: [BPEdgeCrossing]) -> [BPBezierContour] {
        
        var contours: [BPBezierContour] = []
        for crossing in crossings {
            if let crossingEdge = crossing.edge {
                if let contour = crossingEdge.contour {
                    if contours.filter({ el in el === contour }).count == 0 {
                        contours.append(contour)
                    }
                }
            }
        }
        return contours
    }

    fileprivate func removeContourCrossings(_ crossings1: inout [BPEdgeCrossing], thatDontAppearIn crossings2: [BPEdgeCrossing]) {
        
        var containersToRemove: [BPBezierContour] = []
        for crossingToTest in crossings1 {
            var existsInOther = true
            if let containerToTest = crossingToTest.edge?.contour {
                for crossing in crossings2 {
                    if crossing.edge?.contour === containerToTest {
                        existsInOther = true
                        break
                    }
                }
                if !existsInOther {
                    containersToRemove.append(containerToTest)
                }
            }
        }
        removeCrossings(&crossings1, forContours: containersToRemove)
    }
    
    fileprivate func removeContoursThatDontContain(_ crossings: inout [BPEdgeCrossing]) {
        
        var containersToRemove: [BPBezierContour] = []
        
        for crossingToTest in crossings {
            if let containerToTest = crossingToTest.edge?.contour {
                var count = 0
                for crossing in crossings {
                    if crossing.edge?.contour === containerToTest {
                        count += 1
                    }
                }
                if count.isEven {
                    containersToRemove.append(containerToTest)
                }
            }
        }
        removeCrossings(&crossings, forContours: containersToRemove)
    }
    
    fileprivate func removeCrossings(_ crossings: inout [BPEdgeCrossing], forContours containersToRemove: [BPBezierContour]) {
        var crossingsToRemove: [BPEdgeCrossing] = []
        for contour in containersToRemove {
            for crossing in crossings {
                if crossing.edge?.contour === contour {
                    crossingsToRemove.append(crossing)
                }
            }
        }
        for crossing in crossingsToRemove {
            for (index, element) in crossings.enumerated() {
                if element === crossing {
                    crossings.remove(at: index)
                    break
                }
            }
        }
    }
    
    fileprivate func markAllCrossingsAsUnprocessed() {
        for contour in _contours {
            for edge in contour.edges {
                
                edge.crossingsWithBlock() {
                    (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
                    crossing.processed = false
                    return (false, false)
                }
                
            }
        }
    }
    
    fileprivate var firstUnprocessedCrossing: BPEdgeCrossing? {
        for contour in _contours {
            for edge in contour.edges {
                var unprocessedCrossing: BPEdgeCrossing?
                edge.crossingsWithBlock() {
                    (crossing: BPEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
                    if crossing.isSelfCrossing {
                        return (false, false)
                    }
                    if !crossing.isProcessed {
                        unprocessedCrossing = crossing
                        return (true, true)
                    }
                    return (false, false)
                }
                if unprocessedCrossing != nil {
                    return unprocessedCrossing!
                }
            }
        }
        return nil
    }
    
    fileprivate var bezierGraphFromIntersections: BPBezierGraph {
        let result = BPBezierGraph()
        var optCrossing: BPEdgeCrossing? = firstUnprocessedCrossing
        while var crossing = optCrossing {
            let contour = BPBezierContour()
            result.addContour(contour)
            
            while !crossing.isProcessed {
                crossing.processed = true
                
                if crossing.isEntry {
                    contour.addCurveFrom(crossing, to: crossing.nextNonself)
                    
                    if let nextNon = crossing.nextNonself {
                        crossing = nextNon
                    } else {
                        if let crossingEdge = crossing.edge {
                            var edge: BPBezierCurve = crossingEdge.next
                            while !edge.hasNonselfCrossings {
                                contour.addCurve(edge.clone())
                                edge = edge.next
                            }
                            crossing = edge.firstNonselfCrossing!
                            contour.addCurveFrom(nil, to: crossing)
                        }
                    }
                } else {
                    contour.addReverseCurveFrom(crossing.previousNonself, to: crossing)
                    if let prevNonself = crossing.previousNonself {
                        crossing = prevNonself
                    } else {
                        if let crossingEdge = crossing.edge {
                            var edge: BPBezierCurve = crossingEdge.previous
                            while !edge.hasNonselfCrossings {
                                contour.addReverseCurve(edge)
                                edge = edge.previous
                            }
                            crossing = edge.lastNonselfCrossing!
                            contour.addReverseCurveFrom(crossing, to: nil)
                        } else {
                            print("This is bad, really bad")
                        }
                    }
                }
                crossing.processed = true
                crossing = crossing.counterpart!
            }
            optCrossing = firstUnprocessedCrossing
        }
        return result
    }
    
    fileprivate func removeCrossings() {
        for contour in _contours {
            for edge in contour.edges {
                edge.removeAllCrossings()
            }
        }
    }
    
    fileprivate func removeOverlaps() {
        for contour in _contours {
            contour.removeAllOverlaps()
        }
    }
    
    fileprivate func addContour(_ contour: BPBezierContour) {
        _contours.append(contour)
        _bounds = CGRect.null
    }
    
    fileprivate var nonintersectingContours: [BPBezierContour] {
        var contours: [BPBezierContour] = []
        for contour in self.contours {
            if contour.intersectingContours.count == 0 {
                contours.append(contour)
            }
        }
        return contours
    }
    
    func debuggingInsertCrossingsForUnionWithBezierGraph(_ otherGraph: inout BPBezierGraph) {
        debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: false, markOtherInside: false)
    }
    
    func debuggingInsertCrossingsForIntersectWithBezierGraph(_ otherGraph: inout BPBezierGraph) {
        debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: true, markOtherInside: true)
    }
    
    func debuggingInsertCrossingsForDifferenceWithBezierGraph(_ otherGraph: inout BPBezierGraph) {
        debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: false, markOtherInside: true)
    }
    
    fileprivate func debuggingInsertCrossingsWithBezierGraph(_ otherGraph: inout BPBezierGraph, markInside: Bool, markOtherInside: Bool) {
    
        self.removeCrossings()
        otherGraph.removeCrossings()
        self.removeOverlaps()
        otherGraph.removeOverlaps()
    
        insertCrossingsWithBezierGraph(otherGraph)
        self.insertSelfCrossings()
        otherGraph.insertSelfCrossings()
        
        self.markCrossingsAsEntryOrExitWithBezierGraph(otherGraph, markInside: markInside)
        otherGraph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: markOtherInside)
    }

    fileprivate func debuggingInsertIntersectionsWithBezierGraph(_ otherGraph: inout BPBezierGraph) {
        self.removeCrossings()
        otherGraph.removeCrossings()
        self.removeOverlaps()
        otherGraph.removeOverlaps()
        
        for ourContour in contours {
            for ourEdge in ourContour.edges {
                for theirContour in otherGraph.contours {
                    for theirEdge in theirContour.edges {
                        var intersectRange: BPBezierIntersectRange?
                        ourEdge.intersectionsWithBezierCurve(theirEdge, overlapRange: &intersectRange) {
                            (intersection: BPBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
                            
                            let ourCrossing = BPEdgeCrossing(intersection: intersection)
                            let theirCrossing = BPEdgeCrossing(intersection: intersection)
                            ourCrossing.counterpart = theirCrossing
                            theirCrossing.counterpart = ourCrossing
                            ourEdge.addCrossing(ourCrossing)
                            theirEdge.addCrossing(theirCrossing)
                            return (false, false)
                        }
                    }
                }
            }
        }
    }
    
}
