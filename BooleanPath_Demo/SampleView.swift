//
//  SampleView.swift
//  BooleanPath_Demo
//
//  Created by Takuto Nakamura on 2018/10/24.
//  Copyright © 2018 Takuto Nakamura. All rights reserved.
//

import Cocoa
import BooleanPath

class SampleView: NSView {

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let w: CGFloat = self.frame.width
        let h: CGFloat = self.frame.height
        NSColor.black.set()
        
        let pathA = NSBezierPath(rect: NSRect(x: w / 10 - 30, y: h / 2 - 30, width: 60, height: 60))
        let pathB = NSBezierPath(ovalIn: NSRect(x: w / 10, y: h / 2, width: 50, height: 50))
        pathA.stroke()
        pathB.stroke()
        
        let unionPath: NSBezierPath = pathA.union(pathB)
        unionPath.transform(using: AffineTransform(translationByX: w / 5, byY: 0))
        unionPath.fill()
        
        let intersectionPath: NSBezierPath = pathA.intersection(pathB)
        intersectionPath.transform(using: AffineTransform(translationByX: 2 * w / 5, byY: 0))
        intersectionPath.fill()
        
        let subtractionPath: NSBezierPath = pathA.subtraction(pathB)
        subtractionPath.transform(using: AffineTransform(translationByX: 3 * w / 5, byY: 0))
        subtractionPath.fill()
        
        let differencePath: NSBezierPath = pathA.difference(pathB)
        differencePath.transform(using: AffineTransform(translationByX: 4 * w / 5, byY: 0))
        differencePath.fill()
    }
    
}
