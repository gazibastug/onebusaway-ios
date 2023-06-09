//
//  OBAListViewAction.swift
//  OBAKit
//
//  Created by Alan Chu on 10/10/20.
//

import OBAKitCore
import UIKit

public typealias OBAListViewAction<Item: OBAListViewItem> = (Item) -> Void

// This needs to be declared by itself. If you declare it under OBAListViewAction,
// it makes it a generic and messes things up.
public enum OBAListViewContextualActionStyle {
    case destructive
    case normal
}

/// An action to display when the user swipes a list view row.
public struct OBAListViewContextualAction<Item: OBAListViewItem> {
    /// The style applied to the action button.
    public var style: OBAListViewContextualActionStyle = .normal

    /// The title of the action button.
    public var title: String?

    /// The image used for the action button.
    public var image: UIImage?

    // MARK: Colors
    /// The text color of the action button.
    public var textColor: UIColor = ThemeColors.shared.lightText

    /// The background color of the action button.
    public var backgroundColor: UIColor = ThemeColors.shared.blue

    // MARK: Behaviors
    /// A Boolean value that determines whether the actions menu is automatically hidden upon selection.
    public var hidesWhenSelected: Bool = false

    public var item: Item?
    public var handler: OBAListViewAction<Item>?

    public var contextualAction: UIContextualAction {
        let style: UIContextualAction.Style
        switch self.style {
        case .destructive: style = .destructive
        case .normal: style = .normal
        }

        // TODO: adopt uicontextualaction's handler's parameters
        let action = UIContextualAction(style: style, title: self.title) { _, _, success in
            guard let handler = self.handler, let item = self.item else { return }
            if hidesWhenSelected {
                success(true)
            }
            handler(item)
        }

        action.image = self.image
        action.backgroundColor = self.backgroundColor

        return action
    }
}
