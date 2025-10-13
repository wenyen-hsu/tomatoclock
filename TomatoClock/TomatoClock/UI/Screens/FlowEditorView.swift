//
//  FlowEditorView.swift
//  TomatoClock
//
//  Created on 2025-10-19
//

import SwiftUI
import UniformTypeIdentifiers

struct FlowEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var workingFlow: TimerFlowConfiguration
    @State private var draggingCycle: FocusCycleConfiguration?

    let defaultFocusDuration: TimeInterval
    let defaultShortBreakDuration: TimeInterval
    let defaultLongBreakDuration: TimeInterval
    let onSave: (TimerFlowConfiguration) -> Void

    init(
        flow: TimerFlowConfiguration,
        defaultFocusDuration: TimeInterval,
        defaultShortBreakDuration: TimeInterval,
        defaultLongBreakDuration: TimeInterval,
        onSave: @escaping (TimerFlowConfiguration) -> Void
    ) {
        _workingFlow = State(initialValue: flow)
        self.defaultFocusDuration = defaultFocusDuration
        self.defaultShortBreakDuration = defaultShortBreakDuration
        self.defaultLongBreakDuration = defaultLongBreakDuration
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                FlowTimelineView(
                    flow: workingFlow,
                    activeStepID: nil
                )
                .padding(.horizontal, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(workingFlow.cycles.indices), id: \.self) { index in
                            cycleCard(for: index)
                        }

                        Button(action: addCycle) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color("PrimaryRed"))
                                Text("新增週期")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("TextDark"))
                            }
                            .frame(width: 140, height: 160)
                            .background(Color("SecondaryGray"))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("編輯流程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func cycleCard(for index: Int) -> some View {
        let cycleBinding = Binding(
            get: { workingFlow.cycles[index] },
            set: { workingFlow.cycles[index] = $0 }
        )
        let cycleValue = cycleBinding.wrappedValue

        FlowCycleEditorCard(
            cycle: cycleBinding,
            index: index,
            canRemove: workingFlow.cycles.count > 1,
            defaultShortBreakDuration: defaultShortBreakDuration,
            defaultLongBreakDuration: defaultLongBreakDuration,
            onRemove: { removeCycle(cycleValue.id) },
            onDuplicate: { duplicateCycle(cycleValue) }
        )
        .opacity(draggingCycle?.id == cycleValue.id ? 0.7 : 1)
        .onDrag {
            draggingCycle = cycleValue
            return NSItemProvider(object: cycleValue.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: FlowCycleDropDelegate(
                item: cycleValue,
                cycles: $workingFlow.cycles,
                draggingItem: $draggingCycle
            )
        )
    }

    private func addCycle() {
        if let last = workingFlow.cycles.last {
            duplicateCycle(last)
        } else {
            withAnimation(.easeInOut) {
                let rest = RestConfiguration(mode: .shortBreak, duration: defaultShortBreakDuration)
                let newCycle = FocusCycleConfiguration(
                    focusDuration: defaultFocusDuration,
                    rest: rest
                )
                workingFlow.cycles.append(newCycle)
            }
        }
    }

    private func removeCycle(_ id: UUID) {
        guard workingFlow.cycles.count > 1 else { return }
        withAnimation(.easeInOut) {
            workingFlow.cycles.removeAll { $0.id == id }
        }
    }

    private func duplicateCycle(_ cycle: FocusCycleConfiguration) {
        withAnimation(.easeInOut) {
            let duplicatedRest: RestConfiguration? = cycle.rest.map { RestConfiguration(mode: $0.mode, duration: $0.duration) }
            let duplicate = FocusCycleConfiguration(
                focusDuration: cycle.focusDuration,
                rest: duplicatedRest
            )
            workingFlow.cycles.append(duplicate)
        }
    }

    private func saveChanges() {
        var sanitized = workingFlow
        sanitized.ensureMinimumCycle()
        onSave(sanitized)
        dismiss()
    }
}

private struct FlowCycleDropDelegate: DropDelegate {
    let item: FocusCycleConfiguration
    @Binding var cycles: [FocusCycleConfiguration]
    @Binding var draggingItem: FocusCycleConfiguration?

    func dropEntered(info: DropInfo) {
        guard let currentDragging = draggingItem else { return }
        if currentDragging == item { return }

        guard let fromIndex = cycles.firstIndex(of: currentDragging),
              let toIndex = cycles.firstIndex(of: item) else { return }

        if fromIndex != toIndex {
            withAnimation(.easeInOut) {
                let moving = cycles.remove(at: fromIndex)
                var targetIndex = toIndex
                if fromIndex < toIndex {
                    targetIndex -= 1
                }
                targetIndex = max(0, min(targetIndex, cycles.count))
                cycles.insert(moving, at: targetIndex)
                draggingItem = moving
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}

private struct FlowCycleEditorCard: View {
    @Binding var cycle: FocusCycleConfiguration
    let index: Int
    let canRemove: Bool
    let defaultShortBreakDuration: TimeInterval
    let defaultLongBreakDuration: TimeInterval
    let onRemove: () -> Void
    let onDuplicate: () -> Void

    private enum RestOption: String, CaseIterable {
        case none
        case short
        case long

        var title: String {
            switch self {
            case .none:
                return "無"
            case .short:
                return "短"
            case .long:
                return "長"
            }
        }
    }

    private var focusMinutesBinding: Binding<Double> {
        Binding(
            get: { cycle.focusDuration / 60 },
            set: { cycle.focusDuration = max(60, min(3600, $0 * 60)) }
        )
    }

    private var restSelectionBinding: Binding<RestOption> {
        Binding(
            get: {
                guard let rest = cycle.rest else { return .none }
                return rest.mode == .longBreak ? .long : .short
            },
            set: { newValue in
                switch newValue {
                case .none:
                    cycle.rest = nil
                case .short:
                    let current = cycle.rest?.mode == .shortBreak ? cycle.rest?.duration ?? defaultShortBreakDuration : defaultShortBreakDuration
                    cycle.rest = RestConfiguration(mode: .shortBreak, duration: current)
                case .long:
                    let current = cycle.rest?.mode == .longBreak ? cycle.rest?.duration ?? defaultLongBreakDuration : defaultLongBreakDuration
                    cycle.rest = RestConfiguration(mode: .longBreak, duration: current)
                }
            }
        )
    }

    private var restMinutesBinding: Binding<Double> {
        Binding(
            get: { (cycle.rest?.duration ?? defaultShortBreakDuration) / 60 },
            set: { newValue in
                guard var rest = cycle.rest else { return }
                rest.duration = max(60, min(3600, newValue * 60))
                cycle.rest = rest
            }
        )
    }

    private var focusMinutesLabel: String {
        "\(Int(round(focusMinutesBinding.wrappedValue))) 分鐘"
    }

    private var restMinutesLabel: String {
        "\(Int(round(restMinutesBinding.wrappedValue))) 分鐘"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("第 \(index + 1) 組")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextDark"))

                Spacer()

                Button(action: onDuplicate) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                }

                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("專注時間")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextDark"))

                Slider(value: focusMinutesBinding, in: 1...60, step: 1)
                    .accentColor(Color("PrimaryRed"))

                Text(focusMinutesLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("休息選項")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextDark"))

                Picker("休息選項", selection: restSelectionBinding) {
                    ForEach(RestOption.allCases, id: \.self) { option in
                        Text(option.title)
                    }
                }
                .pickerStyle(.segmented)

                if cycle.rest != nil {
                    Slider(value: restMinutesBinding, in: 1...60, step: 1)
                        .accentColor(Color.blue)

                    Text(restMinutesLabel)
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextDark").opacity(0.7))
                }
            }
        }
        .padding(20)
        .frame(width: 240, alignment: .leading)
        .background(Color("BackgroundWhite"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("SecondaryGray"), lineWidth: 1)
        )
    }
}

#Preview {
    FlowEditorView(
        flow: .default,
        defaultFocusDuration: 25 * 60,
        defaultShortBreakDuration: 5 * 60,
        defaultLongBreakDuration: 15 * 60,
        onSave: { _ in }
    )
}
