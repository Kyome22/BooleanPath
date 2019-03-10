//
//  BPBezierIntersectRange.swift
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

public class BPBezierIntersectRange {
    var _curve1: BPBezierCurve
    var _parameterRange1: BPRange
    var _curve1LeftBezier: BPBezierCurve?
    var _curve1MiddleBezier: BPBezierCurve?
    var _curve1RightBezier: BPBezierCurve?
    
    var _curve2: BPBezierCurve
    var _parameterRange2: BPRange
    var _curve2LeftBezier: BPBezierCurve?
    var _curve2MiddleBezier: BPBezierCurve?
    var _curve2RightBezier: BPBezierCurve?
    
    var needToComputeCurve1 = true
    var needToComputeCurve2 = true
    
    var _reversed: Bool
    
    var curve1: BPBezierCurve {
        return _curve1
    }
    
    var parameterRange1: BPRange {
        return _parameterRange1
    }
    
    var curve2: BPBezierCurve {
        return _curve2
    }
    
    var parameterRange2: BPRange {
        return _parameterRange2
    }
    
    var reversed: Bool {
        return _reversed
    }
    
    init(curve1: BPBezierCurve, parameterRange1: BPRange, curve2: BPBezierCurve, parameterRange2: BPRange, reversed: Bool) {
        _curve1 = curve1
        _parameterRange1 = parameterRange1
        _curve2 = curve2
        _parameterRange2 = parameterRange2
        _reversed = reversed
    }
    
    var curve1LeftBezier: BPBezierCurve {
        computeCurve1()
        return _curve1LeftBezier!
    }
    
    var curve1OverlappingBezier: BPBezierCurve {
        computeCurve1()
        return _curve1MiddleBezier!
    }
    
    var curve1RightBezier: BPBezierCurve {
        computeCurve1()
        return _curve1RightBezier!
    }
    
    var curve2LeftBezier: BPBezierCurve {
        computeCurve2()
        return _curve2LeftBezier!
    }
    
    var curve2OverlappingBezier: BPBezierCurve {
        computeCurve2()
        return _curve2MiddleBezier!
    }
    
    var curve2RightBezier: BPBezierCurve {
        computeCurve2()
        return _curve2RightBezier!
    }
    
    var isAtStartOfCurve1: Bool {
        return BPAreValuesCloseWithOptions(_parameterRange1.minimum, value2: 0.0, threshold: BPParameterCloseThreshold)
    }
    
    var isAtStopOfCurve1: Bool {
        return BPAreValuesCloseWithOptions(_parameterRange1.maximum, value2: 1.0, threshold: BPParameterCloseThreshold)
    }
    
    var isAtStartOfCurve2: Bool {
        return BPAreValuesCloseWithOptions(_parameterRange2.minimum, value2: 0.0, threshold: BPParameterCloseThreshold)
    }
    
    var isAtStopOfCurve2: Bool {
        return BPAreValuesCloseWithOptions(_parameterRange2.maximum, value2: 1.0, threshold: BPParameterCloseThreshold)
    }
    
    var middleIntersection: BPBezierIntersection {
        return BPBezierIntersection (
            curve1: _curve1,
            param1: (_parameterRange1.minimum + _parameterRange1.maximum) / 2.0,
            curve2: _curve2,
            param2: (_parameterRange2.minimum + _parameterRange2.maximum) / 2.0
        )
    }
    
    func merge(_ other: BPBezierIntersectRange) {
        _parameterRange1 = BPRangeUnion(_parameterRange1, range2: other._parameterRange1);
        _parameterRange2 = BPRangeUnion(_parameterRange2, range2: other._parameterRange2);
        
        clearCache()
    }
    
    fileprivate func clearCache() {
        needToComputeCurve1 = true
        needToComputeCurve2 = true
        
        _curve1LeftBezier = nil
        _curve1MiddleBezier = nil
        _curve1RightBezier = nil
        _curve2LeftBezier = nil
        _curve2MiddleBezier = nil
        _curve2RightBezier = nil
    }
    
    fileprivate func computeCurve1() {
        if needToComputeCurve1 {
            let swr = _curve1.splitSubcurvesWithRange(_parameterRange1, left: true, middle: true, right: true)
            _curve1LeftBezier = swr.left
            _curve1MiddleBezier = swr.mid
            _curve1RightBezier = swr.right
            needToComputeCurve1 = false
        }
    }
    
    fileprivate func computeCurve2() {
        if needToComputeCurve2 {
            let swr = _curve2.splitSubcurvesWithRange(_parameterRange2, left: true, middle: true, right: true)
            _curve2LeftBezier = swr.left
            _curve2MiddleBezier = swr.mid
            _curve2RightBezier = swr.right
            needToComputeCurve2 = false
        }
    }
}
