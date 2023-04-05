import SwiftUI

extension View {
    func onAppearOrChange<T: Equatable>(_ value: T, perform: @escaping (T) -> Void) -> some View {
        self.onAppear(perform: { perform(value) }).onChange(of: value, perform: perform)
    }
}
