//
//  CGPath.swift
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

import QuartzCore

typealias MyPathApplier = @convention(block) (UnsafePointer<CGPathElement>) -> Void

private func myPathApply(_ path: CGPath!, block: @escaping MyPathApplier) {
    let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
        let block = unsafeBitCast(info, to: MyPathApplier.self)
        block(element)
    }
    path.apply(info: unsafeBitCast(block, to: UnsafeMutableRawPointer.self), function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
}

public enum PathElement {
    case move(to: CGPoint)
    case line(to: CGPoint)
    case quadCurve(to: CGPoint, via: CGPoint)
    case cubicCurve(to: CGPoint, v1: CGPoint, v2: CGPoint)
    case close
}

public extension CGPath {
    
    func apply(_ fn: @escaping (PathElement) -> Void) {
        myPathApply(self) { element in
            let points = element.pointee.points
            switch (element.pointee.type) {
                
            case CGPathElementType.moveToPoint:
                fn(.move(to: points[0]))
                
            case .addLineToPoint:
                fn(.line(to: points[0]))
                
            case .addQuadCurveToPoint:
                fn(.quadCurve(to: points[1], via: points[0]))
                
            case .addCurveToPoint:
                fn(.cubicCurve(to: points[2], v1: points[0], v2: points[1]))
                
            case .closeSubpath:
                fn(.close)
            }
        }
    }
    
}
