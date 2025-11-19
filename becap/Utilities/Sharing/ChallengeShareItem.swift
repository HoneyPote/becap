#if canImport(UIKit)
import UIKit
import LinkPresentation

final class ChallengeShareItem: NSObject, UIActivityItemSource {
    private let challengeTitle: String
    private let message: String
    private let linkURL: URL?
    private let previewImage: UIImage
    private let fallbackURL = URL(string: "https://becap.app")!

    init(challenge: Challenge, message: String, linkURL: URL?, previewImage: UIImage) {
        self.challengeTitle = challenge.title
        self.message = message
        self.linkURL = linkURL
        self.previewImage = previewImage
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        "Rejoins \"\(challengeTitle)\" sur Becap"
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        let url = linkURL ?? fallbackURL
        metadata.originalURL = url
        metadata.url = url
        metadata.title = "Becap – \(challengeTitle)"
        metadata.imageProvider = NSItemProvider(object: previewImage)
        metadata.iconProvider = NSItemProvider(object: previewImage)
        return metadata
    }
}
#endif
