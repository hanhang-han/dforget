import SwiftUI
import SwiftData

struct ReminderFeedView: View {
    @State private var viewModel = ReminderFeedViewModel()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.reminders.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(viewModel.reminders) { item in
                            if item.isSmallNote {
                                SmallNoteCardView(
                                    item: item,
                                    onTap: { viewModel.markAsRead(item) },
                                    onFeedback: { type in viewModel.setFeedback(item, type: type) }
                                )
                            } else {
                                ReminderCardView(
                                    item: item,
                                    onTap: { viewModel.markAsRead(item) },
                                    onFeedback: { type in viewModel.setFeedback(item, type: type) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("灵动提醒")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.generateNewReminder()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .refreshable {
                viewModel.generateNewReminder()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("还没有提醒")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            Text("下拉或点击 + 生成第一条提醒")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}
