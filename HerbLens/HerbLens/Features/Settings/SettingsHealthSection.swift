import SwiftUI

/// Inline health-profile editor. Coordination note (CLAUDE.md ownership §4): once
/// Instance 3 ships a shared `HealthProfileWizard`, swap this for it. Until then the
/// Settings screen owns its own editor so the surface isn't stubbed out.
///
/// UX: goals can be drag-reordered and trimmed, allergies/medications/conditions are
/// tag chips with inline add, experience level is a segmented picker.
struct SettingsHealthSection: View {
    @Binding var draft: HealthProfileDraft
    let isDirty: Bool
    let isSaving: Bool
    let onSave: @Sendable () -> Void

    @State private var newGoal: String = ""
    @State private var newAllergy: String = ""
    @State private var newMedication: String = ""
    @State private var newCondition: String = ""

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                header

                goalsBlock
                tagsBlock(
                    title: "Allergies",
                    items: $draft.allergies,
                    buffer: $newAllergy,
                    placeholder: "Add an allergy"
                )
                tagsBlock(
                    title: "Medications",
                    items: $draft.medications,
                    buffer: $newMedication,
                    placeholder: "Add a medication"
                )
                tagsBlock(
                    title: "Conditions",
                    items: $draft.conditions,
                    buffer: $newCondition,
                    placeholder: "Add a condition"
                )
                experienceBlock

                saveButton
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Health profile")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer()
            if isDirty {
                Text("Unsaved changes")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.amber)
            }
        }
    }

    // MARK: - Goals

    private var goalsBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Priorities")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)

            if draft.goals.isEmpty {
                Text("Add the health goals HerbLens should tune scoring for.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary.opacity(0.8))
            } else {
                ForEach(Array(draft.goals.enumerated()), id: \.element.id) { index, goal in
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("\(index + 1).")
                            .font(Theme.Font.captionMono)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(goal.name)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        if index > 0 {
                            Button {
                                draft.goals.swapAt(index, index - 1)
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.Color.forest)
                        }
                        if index < draft.goals.count - 1 {
                            Button {
                                draft.goals.swapAt(index, index + 1)
                            } label: {
                                Image(systemName: "arrow.down")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.Color.forest)
                        }
                        Button {
                            draft.goals.removeAll { $0.id == goal.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Color.ember)
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack(spacing: Theme.Spacing.xs) {
                TextField("Add a goal (e.g. Better Sleep)", text: $newGoal)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = newGoal.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    draft.goals.append(HealthGoalDraft(name: trimmed))
                    newGoal = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Color.forest)
                }
                .buttonStyle(.plain)
                .disabled(newGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Tag blocks

    @ViewBuilder
    private func tagsBlock(
        title: String,
        items: Binding<[String]>,
        buffer: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)

            if !items.wrappedValue.isEmpty {
                FlowLayout(spacing: Theme.Spacing.xs) {
                    ForEach(items.wrappedValue, id: \.self) { item in
                        HStack(spacing: 4) {
                            Text(item)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Button {
                                items.wrappedValue.removeAll { $0 == item }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Color.textSecondary.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Theme.Color.sage.opacity(0.25))
                        )
                    }
                }
            }

            HStack(spacing: Theme.Spacing.xs) {
                TextField(placeholder, text: buffer)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = buffer.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !items.wrappedValue.contains(trimmed) {
                        items.wrappedValue.append(trimmed)
                    }
                    buffer.wrappedValue = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Color.forest)
                }
                .buttonStyle(.plain)
                .disabled(buffer.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Experience

    private var experienceBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Experience level")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)

            Picker("Experience level", selection: $draft.experienceLevel) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        ZStack {
            PrimaryButton("Save changes", variant: .filled, isDisabled: !isDirty || isSaving) {
                onSave()
            }
            if isSaving {
                ProgressView().tint(Theme.Color.bone)
            }
        }
    }
}

/// Minimal flow layout for tag chips — line-wraps children across the container width
/// without importing a dependency. Behavior is enough for our finite tag counts.
nonisolated struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
