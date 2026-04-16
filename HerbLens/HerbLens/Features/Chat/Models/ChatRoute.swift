import Foundation

/// Deep-link targets for the Chat feature. HerbProfile pushes `.plantContext(plantID)`;
/// the conversation list pushes `.conversation(conversation)` on row tap. `ChatRootView`
/// resolves either path into the right child view.
enum ChatRoute: Hashable, Sendable {
    case plantContext(String)
    case conversation(Conversation)
    case newBlank
}
