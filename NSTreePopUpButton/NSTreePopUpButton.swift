//
//  NSTreePopUpButton.swift
//  FinancesMac
//
//  Created by Matthias Hochgatterer on 26/05/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import AppKit

class NSTreePopUpButton: NSPopUpButton {
    var observedContentKeyPath: String?
    var observedContentObject: AnyObject?
    
    var observedSelectionKeyPath: String?
    var observedSelectionObject: AnyObject?
    
    deinit {
        observedContentObject?.removeObserver(self, forKeyPath: observedContentKeyPath!)
        observedSelectionObject?.removeObserver(self, forKeyPath: observedSelectionKeyPath!)
    }
    
    private struct Context {
        static var SelectionIndex = "SelectionIndex"
        static var Content = "Content"
        static var ContentValues = "ContentValues"
    }
    
    override func bind(binding: String, toObject observable: AnyObject, withKeyPath keyPath: String, options: [NSObject : AnyObject]?) {
        switch binding {
        case NSContentBinding:
            observedContentObject = observable
            observedContentKeyPath = keyPath
            observable.addObserver(self, forKeyPath: keyPath, options: NSKeyValueObservingOptions.Initial, context: &Context.Content)
        case NSSelectedIndexBinding:
            observedSelectionObject = observable
            observedSelectionKeyPath = keyPath
            observable.addObserver(self, forKeyPath: keyPath, options: NSKeyValueObservingOptions.Initial, context: &Context.SelectionIndex)
            break
        default:
            super.bind(binding, toObject: observable, withKeyPath: keyPath, options: options)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch context {
        case &Context.Content:
            if let nodes = object.valueForKeyPath("\(observedContentKeyPath!).childNodes") as? [NSTreeNode] {
                // This replaces the whole menu instance and clears all selected items from the UI
                // But the selection index will be updated by the tree controller automatically
                self.menu = NSMenu.menuForNodes(nodes, action:"onMenuItemSelected:", target: self)
            }
        case &Context.SelectionIndex:
            if let indexPath = object.valueForKeyPath(observedSelectionKeyPath!) as? NSIndexPath {
                menu?.deselectAllItems()
                selectItemsAtIndexPaths(indexPath)
            }
        default:
            break
        }
    }
    
    func onMenuItemSelected(sender: NSMenuItem) {
        menu?.deselectAllItems()
        if let node = sender.representedObject as? NSTreeNode {
            selectItemsAtIndexPaths(node.indexPath)
            if let treeController = self.observedSelectionObject as? NSTreeController {
                if treeController.setSelectionIndexPath(node.indexPath) == false {
                    println("Could not select index path \(node.indexPath)")
                }
            }
        } else {
            assertionFailure("Could not select object for menu item because represented object is not of type NSTreeNode")
        }
    }
    
    func updateCellWithSelectedItems(items: Array<NSMenuItem>) {
        if let cell = self.cell() as? NSPopUpButtonCell {
            // Don't use item from menu
            cell.usesItemFromMenu = false
            
            let item = NSMenuItem(title: "", action: "", keyEquivalent: "")
            if let last = items.last {
                item.title = last.title
            }
            item.representedObject = items
            cell.menuItem = item
        }
    }
    
    private func selectItemsAtIndexPaths(indexPath: NSIndexPath) {
        if let menu = self.menu {
            if let index = menu.selectItemsAtIndexPaths(indexPath) {
                updateCellWithSelectedItems(menu.itemsWithState(NSOnState))
            }
        }
    }
    
    /// :returns: An attributed string by joining the items' titles.
    private func attributedStringFromSelectedItems(items: [NSMenuItem]) -> NSAttributedString {
        let titles = items.map{ $0.title }.reverse()
        var attributedTitle = NSMutableAttributedString()
        for title in titles {
            var attributes = titleAttributes
            if title == titles.first && titles.count > 1 {
                attributes = highlightedTitleAttributes
            } else {
                attributedTitle.appendAttributedString(NSAttributedString(string: " "))
            }
            attributedTitle.appendAttributedString(NSAttributedString(string: title, attributes: attributes))
        }
        return attributedTitle
    }
    
    private let DefaultTitleFontSize = CGFloat(25)
    /// Returns the attributes of a title.
    private var titleAttributes: [NSObject: AnyObject] {
        get {
            var attributes = [NSObject: AnyObject]()
            if let font = self.font {
                var titleFont = font
                if let headerFont = NSFont(name: "HelveticaNeue-Thin", size: DefaultTitleFontSize) {
                    titleFont = headerFont
                }
                attributes[NSFontAttributeName] = titleFont
            }
            
            return attributes
        }
    }
    
    /// Returns the attributes of an highlighted title.
    private var highlightedTitleAttributes: [NSObject: AnyObject] {
        get {
            var attributes = [NSObject: AnyObject]()
            if let font = self.font {
                var titleFont = font
                if let headerFont = NSFont(name: "HelveticaNeue", size: DefaultTitleFontSize) {
                    titleFont = headerFont
                }
                attributes[NSFontAttributeName] = titleFont
            }
            
            return attributes
        }
    }
}

extension NSMenu {

    /// The menu represents the hierarchy of nodes. Every menu item has the `representedObject` set to a node.
    /// This methods returns nil when nodes is empty.
    ///
    /// :returns: A menu for nodes.
    private class func menuForNodes(nodes: NSArray, action: Selector, target: AnyObject) -> NSMenu? {
        if nodes.count == 0 {
            return nil
        }
        
        let menu = NSMenu()
        for node in nodes {
            if let object = node.representedObject as? NSObject {
                let item = NSMenuItem(title: object.description, action: action, keyEquivalent: "")
                item.target = target
                item.representedObject = node
                if let childNodes = node.childNodes as? Array<NSTreeNode> {
                    if let subMenu = menuForNodes(childNodes, action:action, target: target) {
                        item.submenu = subMenu
                    }
                }
                menu.addItem(item)
            }
        }
        return menu
    }
    
    /// Recursively deselect all items in all submenus
    private func deselectAllItems() {
        for i in 0..<numberOfItems {
            if let item = itemAtIndex(i) {
                item.state = NSOffState
                item.submenu?.deselectAllItems()
            }
        }
    }
    
    /// Selects all items in the index path
    private func selectItemsAtIndexPaths(indexPath: NSIndexPath) -> Int? {
        if indexPath.length > 0 {
            var indexes = [Int](count:indexPath.length, repeatedValue: 0)
            indexPath.getIndexes(UnsafeMutablePointer(indexes))
            let selected = indexes.removeAtIndex(0)
            if selected < numberOfItems {
                for i in 0..<numberOfItems {
                    let item = itemAtIndex(i)!
                    if i == selected {
                        item.state = NSOnState
                        let newIndexPath = NSIndexPath(indexes: indexes, length: indexes.count)
                        item.submenu?.selectItemsAtIndexPaths(newIndexPath)
                        break
                    }
                }
                
                return selected
            }
        }
        
        return nil
    }
    
    /// :returns: All item with a specific state.
    private func itemsWithState(state: Int) -> Array<NSMenuItem> {
        var items = [NSMenuItem]()
        for i in 0..<numberOfItems {
            if let item = itemAtIndex(i) {
                if item.state == state {
                    items.append(item)
                }
                if let child = item.submenu {
                    for childItem in child.itemsWithState(state) {
                        items.append(childItem)
                    }
                }
            }
        }
        return items
    }
}

