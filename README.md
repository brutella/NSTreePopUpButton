# NSTreePopUpButton

The `NSTreePopUpButton` class adds supports for binding to a tree controller and displays the tree structure in a hierarchy of menus.

## NSPopUpButton Binding

The `NSPopUpButton` can only display a one dimensional list of objects. The `NSTreePopUpButton` overwrites the binding to `content` and `selectedIndex` to work with a `NSTreeController` instance.

The `content` must be bound to `arrangedObjects` and `selectedIndex` to `selectionIndexPath` of a tree controller instance.

![binding](https://cloud.githubusercontent.com/assets/125641/7907954/0f10a70a-0840-11e5-97cb-232c13facc2f.png)

The `NSTreePopUpButton` creates nested menus to represent the object hierarchy. The state of every menu item in the selected index path is set to `NSOnState`.

![menu](https://cloud.githubusercontent.com/assets/125641/7907953/0f0dff5a-0840-11e5-9e41-e6062ed7b71f.png) 

## Limitations

- The `contentValues` options is currently not supported. You should override the `var description: String` method in your class and return  the value you want to display in the menu.
- The class does not support multiple selections.

# Contact

Matthias Hochgatterer

Github: [https://github.com/brutella](https://github.com/brutella/)

Twitter: [https://twitter.com/brutella](https://twitter.com/brutella)


# License

NSTreePopUpButton is available under the MIT license. See the LICENSE file for more info.