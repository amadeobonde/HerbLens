import Foundation

/// Single source of truth for the onboarding state machine. The associated-value
/// enum encodes transient routing state (the email in-flight, the wizard step,
/// the failure + retry target) without requiring a separate router object.
enum OnboardingStage: Equatable {
    case welcome
    case emailEntry
    case codeEntry(email: String)
    case wizard(step: OnboardingWizardStep)
    case finalizing
    case complete(tier: SubscriptionTier)
    case failed(message: String, retryTo: RetryTarget)

    /// Lightweight retry descriptor so `failed` stays `Equatable` without
    /// dragging a full `OnboardingStage` payload (which would make the enum
    /// indirectly recursive and awkward to test).
    enum RetryTarget: Equatable {
        case emailEntry
        case codeEntry(email: String)
        case wizard(step: OnboardingWizardStep)
        case finalizing
    }
}

enum OnboardingWizardStep: Int, CaseIterable, Equatable {
    case goals
    case allergies
    case medications
    case conditions
    case experience

    var displayIndex: Int { rawValue + 1 }
    static var total: Int { allCases.count }

    var next: OnboardingWizardStep? {
        OnboardingWizardStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingWizardStep? {
        OnboardingWizardStep(rawValue: rawValue - 1)
    }

    var title: String {
        switch self {
        case .goals: "What matters most?"
        case .allergies: "Any allergies?"
        case .medications: "Taking any meds?"
        case .conditions: "Anything else we should know?"
        case .experience: "How herb-savvy are you?"
        }
    }

    var subtitle: String {
        switch self {
        case .goals: "Rank the goals you care about so we can tailor each plant's score."
        case .allergies: "We'll flag plants with cross-reactive ingredients."
        case .medications: "Some herbs don't play well with common meds — we'll warn you."
        case .conditions: "These affect contraindication warnings."
        case .experience: "Sets the depth of explanations we show."
        }
    }
}
