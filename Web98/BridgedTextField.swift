import SwiftUI
import UIKit

struct BridgedTextField: UIViewRepresentable {
    struct Options {
        var placeholder: String = ""

        // Changing these IDs focuses or unfocuses the view
        var focusId: Int = 0
        var unfocusId: Int = 0

        var onFocusChanged: (Bool) -> Void = { _ in }
        var autocapitalization: UITextAutocapitalizationType = .none
        var autocorrection: UITextAutocorrectionType = .no
        var spellChecking: UITextSpellCheckingType = .no
        var keyboardType: UIKeyboardType = .default
        var onReturn: () -> Void = { }
        var alignment: NSTextAlignment = .left
        var selectAllOnFocus: Bool = false
    }

    @Binding var text: String
    var options: Options

    func makeUIView(context: Context) -> _BridgedTextField {
        let view = _BridgedTextField()
        view.onTextChange = { text = $0 }
        view.options = options
        return view
    }

    func updateUIView(_ uiView: _BridgedTextField, context: Context) {
        uiView.text = text
        uiView.options = options
    }
}

class _BridgedTextField: UITextField, UITextFieldDelegate {
    var onTextChange: (String) -> Void = { _ in }

    var options: BridgedTextField.Options = .init() {
        didSet {
            self.placeholder = options.placeholder

            // Update keyboard options
            self.autocapitalizationType = options.autocapitalization
            self.autocorrectionType = options.autocorrection
            self.spellCheckingType = options.spellChecking
            self.keyboardType = options.keyboardType

            self.textAlignment = options.alignment
            
            // Update focus
            if options.focusId != oldValue.focusId {
                DispatchQueue.main.async {
                    _ = self.becomeFirstResponder()
                }
            } else if options.unfocusId != oldValue.unfocusId {
                DispatchQueue.main.async {
                    _ = self.resignFirstResponder()
                }
            }
        }
    }

    init() {
        super.init(frame: .zero)
        self.placeholder = options.placeholder
        self.delegate = self
        self.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        onTextChange(textField.text ?? "")
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            options.onFocusChanged(true)
            if options.selectAllOnFocus {
                DispatchQueue.main.async {
                    self.selectAll(nil)
                }
            }
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            options.onFocusChanged(false)
        }
        return result
    }

    // MARK - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        options.onReturn()
        return true
    }
}
