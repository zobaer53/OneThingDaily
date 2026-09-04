import SwiftUI
import OneThingTodayDomain

struct WeeklyDigestView: View {
    @State var viewModel: WeeklyDigestViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.isAIAvailable {
                    unavailableCard
                } else if viewModel.isLoading {
                    ProgressView("Summarizing your week…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let digest = viewModel.digest {
                    progressCard(digest)
                    summaryCard(digest)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .navigationTitle("Weekly Digest")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var unavailableCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("On-device AI isn't available", systemImage: "sparkles")
                .font(.headline)
            Text("The weekly digest is written by the on-device Foundation Models on this iPhone. It isn't available on this device or with the current settings, so there's nothing to summarize here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func progressCard(_ digest: WeeklyDigest) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Days completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(digest.daysCompleted) of \(digest.daysTotal)")
                    .font(.title.bold())
            }
            Spacer()
            ProgressView(value: Double(digest.daysCompleted), total: Double(max(digest.daysTotal, 1)))
                .progressViewStyle(.circular)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completed \(digest.daysCompleted) of \(digest.daysTotal) days this week")
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryCard(_ digest: WeeklyDigest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(digest.summaryText)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
