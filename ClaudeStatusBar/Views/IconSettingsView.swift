import SwiftUI

struct IconSettingsView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Icon Design")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            ForEach(IconDesignType.allCases, id: \.self) { design in
                Button {
                    viewModel.selectedIconDesign = design
                } label: {
                    HStack(spacing: 8) {
                        iconPreview(for: design)
                            .frame(width: 24, height: 24)
                        Text(design.displayName)
                            .font(.caption)
                        Spacer()
                        if viewModel.selectedIconDesign == design {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func iconPreview(for design: IconDesignType) -> some View {
        if design == .default {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
        } else {
            Image(design.assetName(for: .normal))
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        }
    }
}
