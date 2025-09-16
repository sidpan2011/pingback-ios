import UIKit
import ContactsUI

final class ContactPickerBridge: NSObject, CNContactPickerDelegate {
    static let shared = ContactPickerBridge()
    private var onPick: ((String) -> Void)?

    func present(onPick: @escaping (String) -> Void) {
        self.onPick = onPick

        // Ensure keyboard is dismissed (prevents SystemInputAssistantView constraint issues)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet

        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .topMost else {
                assertionFailure("No rootViewController to present contact picker")
                return
            }

        root.present(picker, animated: true)
        print("🟢 ContactPickerBridge: presented CNContactPickerViewController")
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let full = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let org = contact.organizationName
        let name = full.isEmpty ? (org.isEmpty ? "Unknown" : org) : full
        print("🟢 ContactPickerBridge: didSelect = \(name)")
        onPick?(name)
        onPick = nil
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        print("🟡 ContactPickerBridge: cancel")
        onPick = nil
    }
}

private extension UIViewController {
    var topMost: UIViewController { presentedViewController?.topMost ?? self }
}
