# BooleanPath for macOS
Add boolean operations to NSBezierPath like the pathfinder of Adobe Illustrator.

## About BooleanPath
This is a rewrite of [VectorBoolean](https://github.com/lrtitze/Swift-VectorBoolean) written by Leslie Titze's.  
BooleanPath is written by Swift for macOS.

## Installation
### CocoaPods
```
pod 'BooleanPath'
```

### Carthage
```
github "Kyome22/BooleanPath"
```

## Demo

The sample code is in the project.

![sample](https://github.com/Kyome22/BooleanPath/blob/master/images/sample.png)

## Usage (Example)

```swift
import Cocoa
import BooleanPath

let rectPath = NSBezierPath(rect: NSRect(x: 10, y: 30, width: 60, height: 60))
let circlePath = NSBezierPath(ovalIn: NSRect(x: 25, y: 15, width: 50, height: 50))
  
// Union        
let unionPath: NSBezierPath = rectPath.union(circlePath)
unionPath.fill()

// Intersection
let intersectionPath: NSBezierPath = rectPath.intersection(circlePath)
intersectionPath.fill()
        
// Subtraction
let subtractionPath: NSBezierPath = rectPath.subtraction(circlePath)
subtractionPath.fill()
        
// Difference
let differencePath: NSBezierPath = rectPath.difference(circlePath)
differencePath.fill()
```
