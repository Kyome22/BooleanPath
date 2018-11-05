//
//  SampleView.swift
//  BooleanPath_Demo
//
//  Created by Takuto Nakamura on 2018/10/24.
//  Copyright © 2018 Takuto Nakamura. All rights reserved.
//

import Cocoa
import BooleanPath

extension NSColor {
    convenience init(hex: String, alpha: CGFloat) {
        let v = hex.map { String($0) } + Array(repeating: "0", count: max(6 - hex.count, 0))
        let r = CGFloat(Int(v[0] + v[1], radix: 16) ?? 0) / 255.0
        let g = CGFloat(Int(v[2] + v[3], radix: 16) ?? 0) / 255.0
        let b = CGFloat(Int(v[4] + v[5], radix: 16) ?? 0) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha: 1.0)
    }
    
    class var randomColor: NSColor {
        let r = CGFloat(arc4random_uniform(255) + 1) / 255.0
        let g = CGFloat(arc4random_uniform(255) + 1) / 255.0
        let b = CGFloat(arc4random_uniform(255) + 1) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

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
        
        /*
        let path = NSBezierPath()
        path.lineWidth = 1.0
        path.move(to: NSPoint(x: 30, y: 30))
        path.line(to: NSPoint(x: 30, y: 200))
        path.line(to: NSPoint(x: 50, y: 200))
        path.line(to: NSPoint(x: 50, y: 100))
        path.line(to: NSPoint(x: 70, y: 100))
        path.line(to: NSPoint(x: 70, y: 200))
        path.line(to: NSPoint(x: 90, y: 200))
        path.line(to: NSPoint(x: 90, y: 150))
        path.line(to: NSPoint(x: 110, y: 150))
        path.line(to: NSPoint(x: 110, y: 190))
        path.line(to: NSPoint(x: 130, y: 190))
        path.line(to: NSPoint(x: 130, y: 30))
        path.close()
        path.fill()
        
        let pathB = NSBezierPath(rect: NSRect(x: 20, y: 160, width: 140, height: 190)).subtraction(path)
        pathB.transform(using: AffineTransform(translationByX: 200, byY: 0))
        
        let pathC = path.difference(NSBezierPath(rect: NSRect(x: 20, y: 160, width: 140, height: 190)))
        pathC.transform(using: AffineTransform(translationByX: 400, byY: 0))
        pathC.fill()
        */
    }
    
}
