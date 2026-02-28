import SwiftUI
import Vortex

// MARK: - Vortex Particle System Configurations

enum EmberParticles {

    /// Slow-moving warm particles that float upward like embers rising from a fire.
    /// Intended as a subtle ambient background effect.
    static var emberGlow: VortexSystem {
        var system = VortexSystem(tags: ["ember"])

        // Emission
        system.position = [0.5, 1.0]
        system.shape = .box(width: 1.0, height: 0.0)
        system.birthRate = 3
        system.lifespan = 5.0
        system.lifespanVariation = 2.0

        // Movement
        system.speed = 0.15
        system.speedVariation = 0.05
        system.angle = .degrees(270)
        system.angleRange = .degrees(30)
        system.attractionCenter = [0.5, 0.0]
        system.attractionStrength = 0.02

        // Appearance
        system.size = 0.04
        system.sizeVariation = 0.02
        system.sizeMultiplierAtDeath = 0.0

        // Colors: warm orange to golden to transparent
        system.colors = .random(
            [
                .init(red: 1.0, green: 0.42, blue: 0.21, opacity: 0.8),   // #FF6B35
                .init(red: 1.0, green: 0.70, blue: 0.28, opacity: 0.7),   // #FFB347
                .init(red: 1.0, green: 0.54, blue: 0.24, opacity: 0.6),   // #FF8A3D
            ]
        )

        return system
    }

    /// Quick burst of particles triggered on send action.
    /// Radiates outward from center for tactile feedback.
    static var fireBurst: VortexSystem {
        var system = VortexSystem(tags: ["spark"])

        // Emission
        system.position = [0.5, 0.5]
        system.shape = .point
        system.birthRate = 0
        system.lifespan = 0.8
        system.lifespanVariation = 0.3
        system.emissionLimit = 30

        // Movement
        system.speed = 0.8
        system.speedVariation = 0.3
        system.angle = .degrees(0)
        system.angleRange = .degrees(360)

        // Appearance
        system.size = 0.03
        system.sizeVariation = 0.015
        system.sizeMultiplierAtDeath = 0.0

        // Colors: bright ember palette
        system.colors = .random(
            [
                .init(red: 1.0, green: 0.42, blue: 0.21, opacity: 1.0),   // #FF6B35
                .init(red: 1.0, green: 0.70, blue: 0.28, opacity: 0.9),   // #FFB347
                .init(red: 1.0, green: 0.85, blue: 0.40, opacity: 0.8),   // Bright gold
                .init(red: 1.0, green: 1.0, blue: 0.80, opacity: 0.7),    // Hot white-yellow
            ]
        )

        return system
    }
}
