import SwiftUI

struct FlavorFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        arrange(
            subviews: subviews,
            width: proposal.width ?? .infinity
        ).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = arrange(subviews: subviews, width: bounds.width)
        for item in result.items {
            subviews[item.index].place(
                at: CGPoint(
                    x: bounds.minX + item.origin.x,
                    y: bounds.minY + item.origin.y
                ),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func arrange(
        subviews: Subviews,
        width: CGFloat
    ) -> (size: CGSize, items: [Item]) {
        var x: CGFloat = .zero
        var y: CGFloat = .zero
        var rowHeight: CGFloat = .zero
        var items: [Item] = []

        for index in subviews.indices {
            let measured = subviews[index].sizeThatFits(.unspecified)
            let itemWidth = min(measured.width, width)
            if x > .zero, x + itemWidth > width {
                x = .zero
                y += rowHeight + spacing
                rowHeight = .zero
            }
            let size = CGSize(width: itemWidth, height: measured.height)
            items.append(
                Item(
                    index: index,
                    origin: CGPoint(x: x, y: y),
                    size: size
                )
            )
            x += itemWidth + spacing
            rowHeight = max(rowHeight, measured.height)
        }

        return (
            CGSize(
                width: width.isFinite ? width : x,
                height: y + rowHeight
            ),
            items
        )
    }

    private struct Item {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }
}
