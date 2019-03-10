//
//  BPContourOverlap.swift
//  BooleanPath
//
//  Oligin is NSBezierPath+Boolean - Created by Andrew Finnell on 2011/05/31.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Based on VectorBoolean - Created by Leslie Titze on 2015/05/19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//
//  Created by Takuto Nakamura on 2019/03/10.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

class BPContourOverlap {
    fileprivate var runs: [BPEdgeOverlapRun] = []
    
    func addOverlap(_ range: BPBezierIntersectRange, forEdge1 edge1: BPBezierCurve, edge2: BPBezierCurve) {
        let overlap = BPEdgeOverlap(range: range, edge1: edge1, edge2: edge2)
        
        var createNewRun = false
        
        if runs.count == 0 {
            createNewRun = true
        } else if runs.count == 1 {
            let inserted = runs.last!.insertOverlap(overlap)
            createNewRun = !inserted
        } else {
            var inserted = runs.last!.insertOverlap(overlap)
            if !inserted {
                inserted = runs[0].insertOverlap(overlap)
            }
            createNewRun = !inserted
        }
        
        if createNewRun {
            let run = BPEdgeOverlapRun()
            run.insertOverlap(overlap)
            runs.append(run)
        }
    }
    
    func doesContainCrossing(_ crossing: BPEdgeCrossing) -> Bool {
        if runs.count == 0 {
            return false
        }
        for run in runs {
            if run.doesContainCrossing(crossing) {
                return true
            }
        }
        return false
    }
    
    func doesContainParameter(_ parameter: Double, onEdge edge: BPBezierCurve) -> Bool {
        if runs.count == 0 {
            return false
        }
        for run in runs {
            if run.doesContainParameter(parameter, onEdge: edge) {
                return true
            }
        }
        return false
    }
    
    func runsWithBlock(_ block: (_ run: BPEdgeOverlapRun) -> Bool) {
        if runs.count == 0 {
            return
        }
        for run in runs {
            let stop = block(run)
            if stop {
                break
            }
        }
    }
    
    func reset() {
        if runs.count == 0 {
            return
        }
        runs.removeAll()
    }
    
    var isComplete: Bool {
        if runs.count == 0 {
            return false
        }
        if runs.count != 1 {
            return false
        }
        return runs[0].isComplete
    }
    
    var isEmpty: Bool {
        return runs.count == 0
    }
    
    var contour1: BPBezierContour? {
        if runs.count == 0 {
            return nil
        }
        let run = runs[0]
        return run.contour1
    }
    
    var contour2: BPBezierContour? {
        if runs.count == 0 {
            return nil
        }
        let run = runs[0]
        return run.contour2
    }
    
    func isBetweenContour(_ contour1: BPBezierContour, andContour contour2: BPBezierContour) -> Bool {
        let myContour1 = self.contour1
        let myContour2 = self.contour2
        return (contour1 === myContour1 && contour2 === myContour2)
            || (contour1 === myContour2 && contour2 === myContour1)
    }
}
