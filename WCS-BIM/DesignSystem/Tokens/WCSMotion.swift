import SwiftUI

public enum WCSMotion {
    public static let fast: Animation = .easeInOut(duration: 0.15)
    public static let standard: Animation = .easeInOut(duration: 0.22)
    public static let sheet: Animation = .spring(response: 0.32, dampingFraction: 0.86)
}
