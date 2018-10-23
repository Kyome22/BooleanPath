//
//  BPBezierIntersection.swift
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

let BPPointCloseThreshold = isRunningOn64BitDevice ? 1e-7 : 1e-3
let BPParameterCloseThreshold = isRunningOn64BitDevice ? 1e-4 : 1e-2

public class BPBezierIntersection {
    
    fileprivate var _location: CGPoint?
    fileprivate var _curve1: BPBezierCurve
    fileprivate var _parameter1: Double
    fileprivate var _curve1LeftBezier: BPBezierCurve?
    fileprivate var _curve1RightBezier: BPBezierCurve?
    fileprivate var _curve2: BPBezierCurve
    fileprivate var _parameter2: Double
    fileprivate var _curve2LeftBezier: BPBezierCurve?
    fileprivate var _curve2RightBezier: BPBezierCurve?
    fileprivate var _tangent: Bool = false
    fileprivate var needToComputeCurve1 = true
    fileprivate var needToComputeCurve2 = true
    
    public var location: CGPoint {
        computeCurve1()
        return _location!
    }
    
    var curve1: BPBezierCurve {
        return _curve1
    }
    
    var parameter1: Double {
        return _parameter1
    }
    
    var curve2: BPBezierCurve {
        return _curve2
    }
    
    var parameter2: Double {
        return _parameter2
    }
    
    init(curve1: BPBezierCurve, param1: Double, curve2:BPBezierCurve, param2: Double) {
        _curve1 = curve1
        _parameter1 = param1
        _curve2 = curve2
        _parameter2 = param2
    }
    
    public var isTangent: Bool {
        if isAtEndPointOfCurve {
            return false
        }
        computeCurve1()
        computeCurve2()
        
        let curve1LeftTangent = BPNormalizePoint(BPSubtractPoint(_curve1LeftBezier!.controlPoint2, point2: _curve1LeftBezier!.endPoint2))
        let curve1RightTangent = BPNormalizePoint(BPSubtractPoint(_curve1RightBezier!.controlPoint1, point2: _curve1RightBezier!.endPoint1))
        let curve2LeftTangent = BPNormalizePoint(BPSubtractPoint(_curve2LeftBezier!.controlPoint2, point2: _curve2LeftBezier!.endPoint2))
        let curve2RightTangent = BPNormalizePoint(BPSubtractPoint(_curve2RightBezier!.controlPoint1, point2: _curve2RightBezier!.endPoint1))
        
        return BPArePointsCloseWithOptions(curve1LeftTangent, point2: curve2LeftTangent, threshold: BPPointCloseThreshold)
            || BPArePointsCloseWithOptions(curve1LeftTangent, point2: curve2RightTangent, threshold: BPPointCloseThreshold)
            || BPArePointsCloseWithOptions(curve1RightTangent, point2: curve2LeftTangent, threshold: BPPointCloseThreshold)
            || BPArePointsCloseWithOptions(curve1RightTangent, point2: curve2RightTangent, threshold: BPPointCloseThreshold)
    }
    
    var curve1LeftBezier: BPBezierCurve {
        computeCurve1()
        return _curve1LeftBezier!
    }
    
    var curve1RightBezier: BPBezierCurve {
        computeCurve1()
        return _curve1RightBezier!
    }
    
    var curve2LeftBezier: BPBezierCurve {
        computeCurve2()
        return _curve2LeftBezier!
    }
    
    var curve2RightBezier: BPBezierCurve {
        computeCurve2()
        return _curve2RightBezier!
    }
    
    var isAtStartOfCurve1: Bool {
        return BPAreValuesCloseWithOptions(_parameter1, value2: 0.0, threshold: BPParameterCloseThreshold) || _curve1.isPoint
    }
    
    var isAtStopOfCurve1: Bool {
        return BPAreValuesCloseWithOptions(_parameter1, value2: 1.0, threshold: BPParameterCloseThreshold) || _curve1.isPoint
    }
    
    var isAtEndPointOfCurve1: Bool {
        return self.isAtStartOfCurve1 || self.isAtStopOfCurve1
    }
    
    var isAtStartOfCurve2: Bool {
        return BPAreValuesCloseWithOptions(_parameter2, value2: 0.0, threshold: BPParameterCloseThreshold) || _curve2.isPoint
    }
    
    var isAtStopOfCurve2: Bool {
        return BPAreValuesCloseWithOptions(_parameter2, value2: 1.0, threshold: BPParameterCloseThreshold) || _curve2.isPoint
    }
    
    var isAtEndPointOfCurve2: Bool {
        return self.isAtStartOfCurve2 || self.isAtStopOfCurve2
    }
    
    var isAtEndPointOfCurve: Bool {
        return self.isAtEndPointOfCurve1 || self.isAtEndPointOfCurve2
    }
    
    fileprivate func computeCurve1() {
        if needToComputeCurve1 {
            let pap = _curve1.pointAtParameter(_parameter1)
            _location = pap.point
            _curve1LeftBezier = pap.leftBezierCurve
            _curve1RightBezier = pap.rightBezierCurve
            needToComputeCurve1 = false
        }
    }

    fileprivate func computeCurve2() {
        if needToComputeCurve2 {
            let pap = _curve2.pointAtParameter(_parameter2)
            _curve2LeftBezier = pap.leftBezierCurve
            _curve2RightBezier = pap.rightBezierCurve
            needToComputeCurve2 = false
        }
    }
    
}
