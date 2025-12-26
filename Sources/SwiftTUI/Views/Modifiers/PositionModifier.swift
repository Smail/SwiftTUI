import Foundation

extension View {
    /// Positions the center of this view at the specified coordinates in its parent's coordinate space.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate (column) for the center of the view
    ///   - y: The y-coordinate (line) for the center of the view
    /// - Returns: A view positioned at the specified coordinates
    public func position(x: Extended, y: Extended) -> some View {
        PositionModifier(content: self, x: x, y: y)
    }
}

private struct PositionModifier<Content: View>: View, PrimitiveView, ModifierView {
    let content: Content
    let x: Extended
    let y: Extended

    static var size: Int? { Content.size }

    func buildNode(_ node: Node) {
        node.controls = WeakSet<Control>()
        node.addNode(at: 0, Node(view: content.view))
    }

    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content.view)

        for control in node.controls?.values ?? [] {
            let control = control as! PositionControl

            control.x = x
            control.y = y
        }
    }

    func passControl(_ control: Control, node: Node) -> Control {
        if let positionControl = control.parent {
            return positionControl
        }

        let positionControl = PositionControl(x: x, y: y)

        positionControl.addSubview(control, at: 0)
        node.controls?.add(positionControl)

        return positionControl
    }

    private class PositionControl: Control {
        var x: Extended
        var y: Extended

        init(x: Extended, y: Extended) {
            self.x = x
            self.y = y
        }

        override func size(proposedSize: Size) -> Size {
            // The position modifier takes all available space to enable positioning
            // This is SwiftUI behavior
            return proposedSize
        }

        override func layout(size: Size) {
            super.layout(size: size)

            // First, let the child determine its natural size
            let childSize = children[0].size(proposedSize: size)
            children[0].layout(size: childSize)

            // Calculate position: center coordinates - (size / 2) = top-left corner
            // This places the center of the child at (x, y)
            let topLeftColumn = x - (childSize.width / 2)
            let topLeftLine = y - (childSize.height / 2)

            children[0].layer.frame.position = Position(
                column: topLeftColumn,
                line: topLeftLine
            )
        }
    }
}
