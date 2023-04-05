import SwiftUI

enum ManualTransitionPhase: Equatable {
    case preInsert
    case inserted
    case removed
}

struct ManualTransitionView<Model: Identifiable & Equatable, V: View>: View {
    var models: [Model]
    var removalDuration: TimeInterval = 0.5
    @ViewBuilder var view: (Model, ManualTransitionPhase) -> V

    @State private var sessions = [Model.ID: Session]()
    private struct Session: Identifiable {
        var phase = ManualTransitionPhase.preInsert
        var lastModel: Model
        var id: Model.ID { lastModel.id }
        var insertDate: Date
    }

    var body: some View {
        Group {
            ForEach(sortedSessions) { session in
                view(session.lastModel, session.phase)
            }
        }
        .onChange(of: models) { processChanged(models: $0) }
    }

    private var sortedSessions: [Session] {
        sessions.values.sorted(by: { $0.insertDate < $1.insertDate })
    }

    private func processChanged(models: [Model]) {
        let newIds = Set(models.map(\.id))
        let oldIds = Set(sessions.keys)

        let modelsById = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })

        let removedIds = oldIds.subtracting(newIds)
        let addedIds = newIds.subtracting(oldIds)
        let keptIds = newIds.intersection(oldIds)

        for id in removedIds {
            sessions[id]?.phase = .removed
            DispatchQueue.main.asyncAfter(deadline: .now() + removalDuration) {
                if sessions[id]?.phase == .removed {
                    sessions[id] = nil
                }
            }
        }

        for id in addedIds {
            sessions[id] = .init(lastModel: modelsById[id]!, insertDate: Date())
        }

        DispatchQueue.main.async {
            for (id, session) in sessions {
                if session.phase == .preInsert {
                    sessions[id]?.phase = .inserted
                }
            }
        }

        for id in keptIds {
            sessions[id]?.lastModel = modelsById[id]!
        }
    }
}
