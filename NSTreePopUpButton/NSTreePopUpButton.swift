//
//  NSTreePopUpButton.swift
//  FinancesMac
//
//  Created by Matthias Hochgatterer on 26/05/15.
//  Copyright (c) 2015 Matthias Hochgatterer. All rights reserved.
//

import AppKit

/// The `NSTreePopUpButton` class adds supports for binding to a tree controller and displays the tree structure in a hierarchy of menus.
/// The `content` must be bound to `arrangedObjects` and `selectedIndex` to `selectionIndexPath` of a tree controller instance. This can be done in code or from the Interface Builder.
///
/// **Limitations**
///
/// - The `contentValues` options is currently not supported. You should override the `var description: String` method in your class and return  the value you want to display in the menu.
/// - The class does not support multiple selections.
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
    
    /// Called from a menu item when selected from the user.
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
    
    /// Displays the last items title in the button's cell.
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

