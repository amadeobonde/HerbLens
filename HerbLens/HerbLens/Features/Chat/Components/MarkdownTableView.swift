import SwiftUI

/// Renders a pipe-delimited markdown table as a SwiftUI `Grid`. Header row gets a sage
/// tint; body rows alternate bone / bone-subtle stripes for readability on long
/// contraindication tables.
struct MarkdownTableView: View {
    let header: [String]
    let rows: [[String]]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.sm, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                    Text(cell)
                        .font(Theme.Font.caption.weight(.semibold))
                        .foregroundStyle(Theme.Color.forest)
                        .padding(.vertical, Theme.Spacing.xs)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Theme.Color.sage.opacity(0.18))

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                GridRow {
                    ForEach(0..<header.count, id: \.self) { colIndex in
                        Text(colIndex < row.count ? row[colIndex] : "")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.charcoal)
                            .padding(.vertical, Theme.Spacing.xs)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(rowIndex.isMultiple(of: 2) ? Theme.Color.bone : Theme.Color.bone.opacity(0.55))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.Color.sage.opacity(0.25), lineWidth: 1)
        )
    }
}
