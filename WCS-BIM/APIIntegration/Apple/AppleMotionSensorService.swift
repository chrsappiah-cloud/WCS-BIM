import CoreMotion
import Foundation

@MainActor
@Observable
final class AppleMotionSensorService: MotionSensorProviding {
    private(set) var isActive = false
    private(set) var lastAcceleration: (x: Double, y: Double, z: Double)?
    private(set) var lastAttitudeDegrees: (pitch: Double, roll: Double, yaw: Double)?

    private let manager = CMMotionManager()

    func start() {
        guard !UITestConfiguration.isEnabled else { return }
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lastAcceleration = (
                motion.userAcceleration.x,
                motion.userAcceleration.y,
                motion.userAcceleration.z
            )
            let attitude = motion.attitude
            self.lastAttitudeDegrees = (
                attitude.pitch * 180 / .pi,
                attitude.roll * 180 / .pi,
                attitude.yaw * 180 / .pi
            )
        }
        isActive = true
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        isActive = false
    }
}
