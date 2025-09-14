import SwiftUI
import AuthenticationServices
import EventKit
import UIKit

struct CalendarIntegrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var webAuthSession: ASWebAuthenticationSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button("Connect Google Calendar", action: connectGoogleCalendar)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                Button("Connect Apple Calendar", action: connectAppleCalendar)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                Spacer(minLength: 0)
            }
            // .padding(.horizontal)
            .padding(.top, 16)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Actions

    /// Requests permission for Apple Calendar via EventKit.
    private func connectAppleCalendar() {
        let store = EKEventStore()
        if #available(iOS 17, *) {
            store.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.presentAlert(title: "Calendar Access Failed", message: error.localizedDescription)
                    } else if granted {
                        self.presentAlert(title: "Connected", message: "Apple Calendar access granted.")
                    } else {
                        self.presentAlert(title: "Permission Needed", message: "Please allow calendar access in Settings › Privacy.")
                    }
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.presentAlert(title: "Calendar Access Failed", message: error.localizedDescription)
                    } else if granted {
                        self.presentAlert(title: "Connected", message: "Apple Calendar access granted.")
                    } else {
                        self.presentAlert(title: "Permission Needed", message: "Please allow calendar access in Settings › Privacy.")
                    }
                }
            }
        }
    }

    /// Starts Google OAuth using ASWebAuthenticationSession.
    /// Requires `GOOGLE_CLIENT_ID` and `GOOGLE_REDIRECT_URI` entries in Info.plist.
    private func connectGoogleCalendar() {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
            let redirectURI = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_REDIRECT_URI") as? String,
            let url = googleOAuthURL(clientID: clientID, redirectURI: redirectURI)
        else {
            presentAlert(title: "Missing Configuration", message: "Set GOOGLE_CLIENT_ID and GOOGLE_REDIRECT_URI in Info.plist.")
            return
        }

        let scheme = URL(string: redirectURI)?.scheme ?? ""

        webAuthSession = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callbackURL, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.presentAlert(title: "Google Connect Failed", message: error.localizedDescription)
                } else if let callbackURL = callbackURL {
                    if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                       let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                        self.presentAlert(title: "Google Connected", message: "Auth code received. Exchange it for tokens on your server.\nCode (truncated): \(code.prefix(6))…")
                    } else {
                        self.presentAlert(title: "Google Connect", message: "Returned without an authorization code.")
                    }
                }
            }
        }
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        _ = webAuthSession?.start()
    }

    private func googleOAuthURL(clientID: String, redirectURI: String) -> URL? {
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        let scope = "https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/calendar.readonly"
        comps?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "include_granted_scopes", value: "true"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return comps?.url
    }

    // MARK: - Helpers
    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    CalendarIntegrationView()
}
