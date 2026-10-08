import OmniKeysCore
import SwiftUI

struct ShortcutCard: View {
    let group: ShortcutGroup

    var body: some View {
        Card(title: group.title) {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 9) {
                ForEach(group.rows) { row in
                    GridRow(alignment: .firstTextBaseline) {
                        KeyChips(text: row.keys)
                        Text(row.action)
                            .font(.system(size: 15))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
