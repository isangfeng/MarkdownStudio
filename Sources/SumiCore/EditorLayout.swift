import Foundation

public enum EditorLayout {
    public static let readableWidth: CGFloat = 820
    public static let minimumHorizontalInset: CGFloat = 60
    public static let verticalInset: CGFloat = 40

    public static func textContainerInset(for viewWidth: CGFloat) -> CGSize {
        let horizontalInset = max(minimumHorizontalInset, (viewWidth - readableWidth) / 2)
        return CGSize(width: horizontalInset, height: verticalInset)
    }
}
