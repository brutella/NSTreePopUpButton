//
//  ViewController.swift
//  NSTreePopUpButton
//
//  Created by Matthias Hochgatterer on 29/05/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var nodes: [Node] = {
        let root1 = Node(name: "Root 1")
        root1.addChildren(Node(name: "Child 1"))
        root1.addChildren(Node(name: "Child 2"))
        
        let root2 = Node(name: "Root 2")
        root2.addChildren(Node(name: "Child 1"))
        root2.addChildren(Node(name: "Child 2"))
        root2.addChildren(Node(name: "Child 3"))
        
        return [root1, root2]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

