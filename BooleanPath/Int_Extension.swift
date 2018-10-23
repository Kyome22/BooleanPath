//
//  Int_Extension.swift
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

import Foundation

extension Int {
    
    public var isEven: Bool {
        get {
            return self % 2 == 0
        }
    }
    
    public var isOdd: Bool {
        get {
            return self % 2 == 1
        }
    }
    
}
