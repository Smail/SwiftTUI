import Foundation

public extension View {
    func background(_ color: Color) -> some View {
        return Background(content: self, color: color)
    }
}

private struct Background<Content: View>: View, PrimitiveView, ModifierView {
    let content: Content
    let color: Color

    static var size: Int? { Content.size }

    func buildNode(_ node: Node) {
        node.controls = WeakSet<Control>()
        node.addNode(at: 0, Node(view: content.view))
    }

    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content.view)
        for control in node.controls?.values ?? [] {
            let control = control as! BackgroundControl
            if control.color != color {
                control.color = color
                control.layer.invalidate()
            }
        }
    }

    func passControl(_ control: Control, node: Node) -> Control {
        if let backgroundControl = control.parent { return backgroundControl }
        let backgroundControl = BackgroundControl(color: color)
        backgroundControl.addSubview(control, at: 0)
        node.controls?.add(backgroundControl)
        return backgroundControl
    }

    private class BackgroundControl: Control {
        var color: Color
        private var contentBounds: Rect = Rect(position: .zero, size: .zero)

        init(color: Color) {
            self.color = color
        }

        override func size(proposedSize: Size) -> Size {
            children[0].size(proposedSize: proposedSize)
        }

        override func layout(size: Size) {
            super.layout(size: size)
            children[0].layout(size: size)

            // After layout, calculate actual content bounds from the layer tree
            contentBounds = calculateContentBounds()
        }

        private func calculateContentBounds() -> Rect {
            guard !children.isEmpty else { return Rect(position: .zero, size: .zero) }

            let bounds = getActualContentBounds(of: children[0], offset: .zero)
            return Rect(
                position: Position(column: bounds.minColumn, line: bounds.minLine),
                size: Size(
                    width: bounds.maxColumn - bounds.minColumn,
                    height: bounds.maxLine - bounds.minLine
                )
            )
        }

        private func getActualContentBounds(of control: Control, offset: Position) -> Rect {
            let childOffset = offset + control.layer.frame.position
            let childFrame = control.layer.frame

            // Check if this control has non-flexible content
            let minSize = control.size(proposedSize: Size(width: 0, height: 0))
            let maxSize = control.size(proposedSize: Size(width: .infinity, height: .infinity))

            if minSize.width == maxSize.width && minSize.height == maxSize.height {
                // Fixed size content - use its bounds
                return Rect(
                    minColumn: childOffset.column,
                    minLine: childOffset.line,
                    maxColumn: childOffset.column + childFrame.size.width,
                    maxLine: childOffset.line + childFrame.size.height
                )
            }

            // Flexible container - recurse
            if control.children.isEmpty {
                return Rect.zero
            }

            var minCol: Extended = .infinity
            var minLn: Extended = .infinity
            var maxCol: Extended = 0
            var maxLn: Extended = 0

            for child in control.children {
                let childBounds = getActualContentBounds(of: child, offset: childOffset)

                minCol = min(minCol, childBounds.minColumn)
                minLn = min(minLn, childBounds.minLine)
                maxCol = max(maxCol, childBounds.maxColumn)
                maxLn = max(maxLn, childBounds.maxLine)
            }

            return Rect(minColumn: minCol, minLine: minLn, maxColumn: maxCol, maxLine: maxLn)
        }

        override func cell(at position: Position) -> Cell? {
            // Only fill within the actual content bounds
            if contentBounds.contains(position) {
                return Cell(char: " ", backgroundColor: color)
            }
            return nil
        }
    }
}
