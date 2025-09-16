import Foundation

/// Service for managing message templates with variable substitution
class TemplateService: ObservableObject {
    static let shared = TemplateService()
    
    @Published var templates: [MessageTemplate] = []
    
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "message_templates"
    
    init() {
        loadTemplates()
        
        // Create default templates if none exist
        if templates.isEmpty {
            createDefaultTemplates()
        }
    }
    
    // MARK: - Template Management
    
    func addTemplate(_ template: MessageTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func updateTemplate(_ template: MessageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }
    
    func deleteTemplate(_ template: MessageTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func getTemplate(by id: UUID) -> MessageTemplate? {
        return templates.first { $0.id == id }
    }
    
    func getDefaultTemplate() -> MessageTemplate? {
        return templates.first { $0.isDefault } ?? templates.first
    }
    
    func setDefaultTemplate(_ template: MessageTemplate) {
        // Remove default flag from all templates
        for i in templates.indices {
            templates[i].isDefault = false
        }
        
        // Set new default
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].isDefault = true
            saveTemplates()
        }
    }
    
    // MARK: - Message Creation
    
    func createMessage(
        template: MessageTemplate? = nil,
        firstName: String,
        note: String,
        link: String? = nil,
        selfName: String = "I"
    ) -> String {
        let selectedTemplate = template ?? getDefaultTemplate()
        
        guard let messageTemplate = selectedTemplate else {
            // Fallback to simple message if no template
            return note
        }
        
        return messageTemplate.resolve(
            firstName: firstName,
            note: note,
            link: link,
            selfName: selfName
        )
    }
    
    func createMessage(
        for followUp: FollowUp,
        selfName: String = "I"
    ) -> String {
        let template = followUp.templateId != nil ? getTemplate(by: followUp.templateId!) : nil
        
        return createMessage(
            template: template,
            firstName: followUp.person.firstName,
            note: followUp.note,
            link: followUp.url,
            selfName: selfName
        )
    }
    
    // MARK: - Variable Information
    
    func getAvailableVariables() -> [TemplateVariable] {
        return [
            TemplateVariable(
                name: "{first_name}",
                description: "Contact's first name",
                example: "John"
            ),
            TemplateVariable(
                name: "{note}",
                description: "The follow-up note/content",
                example: "Check on the project status"
            ),
            TemplateVariable(
                name: "{link}",
                description: "Associated URL or link",
                example: "https://example.com"
            ),
            TemplateVariable(
                name: "{self_name}",
                description: "Your name",
                example: "Sarah"
            )
        ]
    }
    
    // MARK: - Persistence
    
    private func loadTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            templates = try decoder.decode([MessageTemplate].self, from: data)
        } catch {
            print("❌ Failed to load templates: \(error)")
            templates = []
        }
    }
    
    private func saveTemplates() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(templates)
            userDefaults.set(data, forKey: templatesKey)
        } catch {
            print("❌ Failed to save templates: \(error)")
        }
    }
    
    private func createDefaultTemplates() {
        let defaultTemplates = [
            MessageTemplate(
                name: "Simple Follow-up",
                content: "Hi {first_name}! {note}",
                isDefault: true
            ),
            MessageTemplate(
                name: "Professional",
                content: "Hi {first_name}, hope you're doing well. {note} Thanks!",
                isDefault: false
            ),
            MessageTemplate(
                name: "Casual",
                content: "Hey {first_name}! {note} 😊",
                isDefault: false
            ),
            MessageTemplate(
                name: "With Link",
                content: "Hi {first_name}! {note}\n\n{link}",
                isDefault: false
            ),
            MessageTemplate(
                name: "Formal",
                content: "Dear {first_name},\n\n{note}\n\nBest regards,\n{self_name}",
                isDefault: false
            )
        ]
        
        templates = defaultTemplates
        saveTemplates()
        
        print("✅ Created \(defaultTemplates.count) default templates")
    }
}

struct TemplateVariable {
    let name: String
    let description: String
    let example: String
}

// MARK: - Template Preview

extension MessageTemplate {
    func preview(
        firstName: String = "John",
        note: String = "Following up on our discussion",
        link: String? = "https://example.com",
        selfName: String = "You"
    ) -> String {
        return resolve(
            firstName: firstName,
            note: note,
            link: link,
            selfName: selfName
        )
    }
}
