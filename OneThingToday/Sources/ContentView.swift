import SwiftUI
import OneThingTodayDomain

struct ContentView: View {
    @State var viewModel: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let session = viewModel.session {
                Text(session.isDone ? "✅ Done for today" : "In progress — phase: \(session.phase.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("What's the one thing today?", text: $viewModel.draftText)
                .textFieldStyle(.roundedBorder)

            Button("Start / Update") {
                Task { await viewModel.start() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty)

            if let session = viewModel.session, !session.taskText.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Saved for today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.taskText)
                        .font(.headline)
                }
                if !session.isDone {
                    Button("Mark Done", role: .none) {
                        Task { await viewModel.complete() }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Text("Persistence check: force-quit the app and reopen it — today's task should still be here.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .navigationTitle("Today")
        .task { await viewModel.load() }
    }
}
