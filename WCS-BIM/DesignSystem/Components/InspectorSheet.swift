import SwiftUI

public struct InspectorParam: Identifiable, Equatable {
    public var id: String
    public var key: String
    public var value: String

    public init(id: String? = nil, key: String, value: String) {
        self.id = id ?? key
        self.key = key
        self.value = value
    }
}

/// Draggable bottom sheet for parametric field editing (BIM inspector pattern).
public struct InspectorSheet: View {
    @Binding private var isPresented: Bool
    @Binding private var params: [InspectorParam]
    private let title: String
    private let onSave: ([InspectorParam]) -> Void

    public init(
        isPresented: Binding<Bool>,
        title: String = "Inspector",
        params: Binding<[InspectorParam]>,
        onSave: @escaping ([InspectorParam]) -> Void
    ) {
        _isPresented = isPresented
        _params = params
        self.title = title
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(WCSColor.separator)
                .frame(width: 36, height: 5)
                .padding(.top, WCSSpacing.xs)
                .accessibilityHidden(true)

            Text(title)
                .font(WCSFont.title(18))
                .foregroundStyle(WCSColor.neutralText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WCSSpacing.md)
                .padding(.top, WCSSpacing.sm)

            ScrollView {
                VStack(spacing: WCSSpacing.md) {
                    ForEach($params) { $param in
                        HStack(alignment: .firstTextBaseline, spacing: WCSSpacing.sm) {
                            Text(param.key)
                                .font(WCSFont.caption())
                                .foregroundStyle(WCSColor.neutralText.opacity(0.8))
                                .frame(width: 110, alignment: .leading)
                            TextField("Value", text: $param.value)
                                .textFieldStyle(.roundedBorder)
                                .font(WCSFont.body(15))
                                .accessibilityIdentifier("Inspector_Param_\(param.key)")
                                .accessibilityLabel("\(param.key) value")
                        }
                    }
                }
                .padding(WCSSpacing.md)
            }

        }
        .background(WCSColor.neutralBG)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: WCSSpacing.sm) {
                Button("Cancel") {
                    isPresented = false
                }
                .font(WCSFont.body(15))
                .foregroundStyle(WCSColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                        .strokeBorder(WCSColor.primary, lineWidth: 1.5)
                )
                .accessibilityIdentifier("Inspector_Cancel")

                PrimaryButton("Save", layout: .fullWidth) {
                    onSave(params)
                    isPresented = false
                }
                .accessibilityIdentifier("Inspector_Save")
            }
            .padding(.horizontal, WCSSpacing.md)
            .padding(.vertical, WCSSpacing.sm)
            .background(WCSColor.neutralBG)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("Inspector_Sheet")
    }
}
