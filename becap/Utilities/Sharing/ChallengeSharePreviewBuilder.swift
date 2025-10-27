#if canImport(UIKit)
import UIKit

enum ChallengeSharePreviewBuilder {
    static func makePreviewImage(for challenge: Challenge, code: String) -> UIImage {
        let size = CGSize(width: 1200, height: 630)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            drawBackground(in: context.cgContext, size: size)
            drawContent(for: challenge, code: code, in: context.cgContext, size: size)
        }
    }

    private static func drawBackground(in context: CGContext, size: CGSize) {
        let colors = [UIColor(red: 37/255, green: 18/255, blue: 89/255, alpha: 1).cgColor,
                      UIColor(red: 128/255, green: 43/255, blue: 161/255, alpha: 1).cgColor,
                      UIColor(red: 233/255, green: 79/255, blue: 140/255, alpha: 1).cgColor]
        let locations: [CGFloat] = [0.0, 0.55, 1.0]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
        context.saveGState()
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: size.width, y: size.height),
                                   options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])
        context.restoreGState()

        let overlay = UIBezierPath(roundedRect: CGRect(x: 60, y: 120, width: size.width - 120, height: size.height - 200), cornerRadius: 36)
        UIColor.white.withAlphaComponent(0.12).setFill()
        overlay.fill()
    }

    private static func drawContent(for challenge: Challenge, code: String, in context: CGContext, size: CGSize) {
        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 78, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let brand = "Becap"
        (brand as NSString).draw(at: CGPoint(x: 80, y: 72), withAttributes: brandAttributes)

        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 34, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.86),
            .paragraphStyle: centeredParagraph(lineSpacing: 6)
        ]
        let tagline = "À 20h00, la routine devient un rendez-vous collectif."
        draw(text: tagline,
             in: CGRect(x: 120, y: 180, width: size.width - 240, height: 120),
             attributes: taglineAttributes)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 60, weight: .heavy),
            .foregroundColor: UIColor.white,
            .paragraphStyle: leftParagraph(lineSpacing: 8)
        ]
        let title = "\"\(challenge.title)\""
        draw(text: title,
             in: CGRect(x: 140, y: 280, width: size.width - 280, height: 160),
             attributes: titleAttributes)

        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92),
            .paragraphStyle: leftParagraph(lineSpacing: 10)
        ]
        let description = "Rejoins le défi et partage chaque jour tes moments forts avec l'équipe."
        draw(text: description,
             in: CGRect(x: 140, y: 420, width: size.width - 320, height: 110),
             attributes: descriptionAttributes)

        if !code.isEmpty {
            drawCodeBadge(code: code, in: context, size: size)
        }

        drawFooter(in: context, size: size)
    }

    private static func drawCodeBadge(code: String, in context: CGContext, size: CGSize) {
        let badgeRect = CGRect(x: 140, y: size.height - 200, width: size.width - 280, height: 120)
        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: 28)
        UIColor.white.withAlphaComponent(0.18).setFill()
        path.fill()

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            .paragraphStyle: leftParagraph(lineSpacing: 4)
        ]
        draw(text: "Code d'accès", in: CGRect(x: badgeRect.minX + 36, y: badgeRect.minY + 20, width: badgeRect.width - 72, height: 32), attributes: titleAttributes)

        let codeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 46, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        (code as NSString).draw(in: CGRect(x: badgeRect.minX + 36, y: badgeRect.minY + 58, width: badgeRect.width - 72, height: 48), withAttributes: codeAttributes)
    }

    private static func drawFooter(in context: CGContext, size: CGSize) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let footer = "Disponible sur l'App Store"
        (footer as NSString).draw(at: CGPoint(x: 140, y: size.height - 56), withAttributes: footerAttributes)
    }

    private static func draw(text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let attributed = NSAttributedString(string: text, attributes: attributes)
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }

    private static func centeredParagraph(lineSpacing: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = lineSpacing
        return paragraph
    }

    private static func leftParagraph(lineSpacing: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineSpacing = lineSpacing
        return paragraph
    }
}
#endif
