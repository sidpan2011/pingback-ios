import UIKit
import ContactsUI

final class ContactPickerBridge: NSObject, CNContactPickerDelegate {
    static let shared = ContactPickerBridge()
    private var onPick: ((String) -> Void)?
    private var onPickPerson: ((Person?) -> Void)?

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

    func presentForPerson(onPick: @escaping (Person?) -> Void) {
        self.onPickPerson = onPick
        self.onPick = nil

        // Ensure keyboard is dismissed
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")

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
        print("🟢 ContactPickerBridge: presented CNContactPickerViewController for Person")
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let full = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let org = contact.organizationName
        let name = full.isEmpty ? (org.isEmpty ? "Unknown" : org) : full
        print("🟢 ContactPickerBridge: didSelect = \(name)")
        
        // If we have onPickPerson callback, create Person with phone numbers
        if let onPickPerson = onPickPerson {
            let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
            
            if phoneNumbers.isEmpty {
                print("⚠️ ContactPickerBridge: Contact has no phone numbers")
                onPickPerson(nil)
            } else {
                // Use the first phone number and normalize it
                let phoneNumber = phoneNumbers[0]
                // Simple E.164 normalization
                let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let e164PhoneNumber: String
                if phoneNumber.hasPrefix("+") {
                    e164PhoneNumber = "+\(digitsOnly)"
                } else {
                    // Default to +1 for US/Canada if no country code (basic fallback)
                    e164PhoneNumber = "+1\(digitsOnly)"
                }
                
                let person = Person(
                    firstName: contact.givenName.isEmpty ? name : contact.givenName,
                    lastName: contact.familyName,
                    phoneNumbers: [e164PhoneNumber]
                )
                print("🟢 ContactPickerBridge: Created Person with phone: \(e164PhoneNumber)")
                onPickPerson(person)
            }
            self.onPickPerson = nil
        } else {
            // Legacy callback for just name
            onPick?(name)
            onPick = nil
        }
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        print("🟡 ContactPickerBridge: cancel")
        onPick = nil
        onPickPerson = nil
    }
}

private extension UIViewController {
    var topMost: UIViewController { presentedViewController?.topMost ?? self }
}
