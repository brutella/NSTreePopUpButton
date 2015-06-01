//
//  Node.swift
//  NSTreePopUpButton
//
//  Created by Matthias Hochgatterer on 29/05/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import Foundation

class Node: NSObject {
    var name: String
    var children = [Node]()
    
    override var debugDescription: String {
        get {
            return name + "\(children.count) children"
        }
    }
    
    override var description: String {
        get {
            return name
        }
    }
    
    convenience override init() {
        self.init(name: "Untitled")
    }
    
    init(name: String) {
        self.name = name
    }
    
    func addChildren(node: Node) {
        children.append(node)
    }
}