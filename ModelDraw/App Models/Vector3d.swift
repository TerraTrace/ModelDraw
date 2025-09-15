//
//  Vector3D.swift
//  SimOrb
//
//  3D vector structure for orbital mechanics calculations
//  Updated: Dual precision support - Double for Swift, Float for Metal
//  Metal Naming Convention: Vector3D_Metal to match EclipseAnalysis.metal exactly
//

import Foundation
import RealityKit


// MARK: - High-Precision Vector (Double precision)

/// High-precision 3D vector for orbital mechanics calculations
/// Uses Double precision for spacecraft engineering accuracy
struct Vector3D {
    
    // MARK: - Properties
    
    /// X-component (Double for high precision calculations)
    let x: Double
    
    /// Y-component (Double for high precision calculations)
    let y: Double
    
    /// Z-component (Double for high precision calculations)
    let z: Double
    
    // MARK: - Initialization
    
    /// Initialize vector with Double components
    /// - Parameters:
    ///   - x: X-component value
    ///   - y: Y-component value
    ///   - z: Z-component value
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Initialize from Metal-compatible vector
    /// - Parameter metalVector: Metal vector to convert to high precision
    init(_ metalVector: Vector3D_Metal) {
        self.x = Double(metalVector.x)
        self.y = Double(metalVector.y)
        self.z = Double(metalVector.z)
    }
    
    // MARK: - Computed Properties
    
    /// Vector magnitude (length) - High precision
    /// Essential for orbital mechanics distance calculations
    var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Unit vector (normalized to magnitude 1) - High precision
    /// Useful for direction calculations in orbital mechanics
    var normalized: Vector3D {
        let mag = magnitude
        guard mag > 0 else { return Vector3D.zero }
        return Vector3D(x: x / mag, y: y / mag, z: z / mag)
    }
    
    /// Metal-compatible version (Float precision)
    /// Used for GPU kernel communication - matches EclipseAnalysis.metal exactly
    var metal: Vector3D_Metal {
        return Vector3D_Metal(x: Float(x), y: Float(y), z: Float(z))
    }
    
    // MARK: - Static Constants
    
    /// Zero vector (origin)
    static let zero = Vector3D(x: 0, y: 0, z: 0)
    
    /// Unit vector in X direction
    static let unitX = Vector3D(x: 1, y: 0, z: 0)
    
    /// Unit vector in Y direction
    static let unitY = Vector3D(x: 0, y: 1, z: 0)
    
    /// Unit vector in Z direction
    static let unitZ = Vector3D(x: 0, y: 0, z: 1)
}

// MARK: - Vector Operations (High Precision)

extension Vector3D {
    
    /// Vector addition
    /// - Parameter other: Vector to add
    /// - Returns: Sum of vectors
    static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    /// Vector subtraction
    /// - Parameter other: Vector to subtract
    /// - Returns: Difference of vectors
    static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    /// Scalar multiplication (Double)
    /// - Parameter scalar: Scalar value to multiply by
    /// - Returns: Scaled vector
    static func * (vector: Vector3D, scalar: Double) -> Vector3D {
        return Vector3D(x: vector.x * scalar, y: vector.y * scalar, z: vector.z * scalar)
    }
    
    /// Scalar multiplication (Double) - commutative
    static func * (scalar: Double, vector: Vector3D) -> Vector3D {
        return vector * scalar
    }
    
    /// Scalar division (Double)
    static func / (vector: Vector3D, scalar: Double) -> Vector3D {
        return Vector3D(x: vector.x / scalar, y: vector.y / scalar, z: vector.z / scalar)
    }
    
    /// Dot product - High precision
    func dot(_ other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }
    
    /// Cross product - High precision
    func cross(_ other: Vector3D) -> Vector3D {
        return Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
}

// MARK: - Metal-Compatible Vector (Float precision)

/// Metal-compatible 3D vector with Float precision
/// Used for GPU kernel communication and graphics rendering
/// CRITICAL: Name matches EclipseAnalysis.metal struct exactly (Vector3D_Metal)
struct Vector3D_Metal {
    
    // MARK: - Properties
    
    /// X-component (Float for Metal compatibility)
    let x: Float
    
    /// Y-component (Float for Metal compatibility)
    let y: Float
    
    /// Z-component (Float for Metal compatibility)
    let z: Float
    
    // MARK: - Initialization
    
    /// Initialize Metal vector with Float components
    /// - Parameters:
    ///   - x: X-component value
    ///   - y: Y-component value
    ///   - z: Z-component value
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Initialize from Double precision Vector3D
    /// - Parameter vector: High precision vector to convert
    init(_ vector: Vector3D) {
        self.x = Float(vector.x)
        self.y = Float(vector.y)
        self.z = Float(vector.z)
    }
    
    // MARK: - Computed Properties
    
    /// Vector magnitude (length)
    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Unit vector (normalized to magnitude 1)
    var normalized: Vector3D_Metal {
        let mag = magnitude
        guard mag > 0 else { return Vector3D_Metal.zero }
        return Vector3D_Metal(x: x / mag, y: y / mag, z: z / mag)
    }
    
    // MARK: - Static Constants
    
    /// Zero vector (origin)
    static let zero = Vector3D_Metal(x: 0, y: 0, z: 0)
    
    /// Unit vector in X direction
    static let unitX = Vector3D_Metal(x: 1, y: 0, z: 0)
    
    /// Unit vector in Y direction
    static let unitY = Vector3D_Metal(x: 0, y: 1, z: 0)
    
    /// Unit vector in Z direction
    static let unitZ = Vector3D_Metal(x: 0, y: 0, z: 1)
}

// MARK: - Vector Operations (Metal Precision)

extension Vector3D_Metal {
    
    /// Vector addition (Float)
    static func + (lhs: Vector3D_Metal, rhs: Vector3D_Metal) -> Vector3D_Metal {
        return Vector3D_Metal(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    /// Vector subtraction (Float)
    static func - (lhs: Vector3D_Metal, rhs: Vector3D_Metal) -> Vector3D_Metal {
        return Vector3D_Metal(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    /// Scalar multiplication (Float)
    static func * (vector: Vector3D_Metal, scalar: Float) -> Vector3D_Metal {
        return Vector3D_Metal(x: vector.x * scalar, y: vector.y * scalar, z: vector.z * scalar)
    }
    
    /// Scalar multiplication (Float) - commutative
    static func * (scalar: Float, vector: Vector3D_Metal) -> Vector3D_Metal {
        return vector * scalar
    }
    
    /// Scalar division (Float)
    static func / (vector: Vector3D_Metal, scalar: Float) -> Vector3D_Metal {
        return Vector3D_Metal(x: vector.x / scalar, y: vector.y / scalar, z: vector.z / scalar)
    }
    
    /// Dot product - Float precision
    func dot(_ other: Vector3D_Metal) -> Float {
        return x * other.x + y * other.y + z * other.z
    }
    
    /// Cross product - Float precision
    func cross(_ other: Vector3D_Metal) -> Vector3D_Metal {
        return Vector3D_Metal(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
}

// MARK: - Debugging Support

extension Vector3D: CustomStringConvertible {
    /// Human-readable description for debugging (high precision)
    var description: String {
        return String(format: "Vector3D(x: %.9f, y: %.9f, z: %.9f)", x, y, z)
    }
}

extension Vector3D_Metal: CustomStringConvertible {
    /// Human-readable description for debugging (Metal precision)
    var description: String {
        return String(format: "Vector3D_Metal(x: %.6f, y: %.6f, z: %.6f)", x, y, z)
    }
}


// MARK: - RealityKit-Compatible Vector (SIMD3<Float> precision)

/// RealityKit-compatible 3D vector with SIMD3<Float> precision
/// Used for RealityKit visualization and 3D scene coordinate communication
/// Provides explicit type safety for RealityKit handoff from orbital mechanics calculations
struct Vector3D_Reality {
    
    // MARK: - Properties
    
    /// SIMD3<Float> vector for direct RealityKit compatibility
    /// Optimized for 3D scene positioning and transformation operations
    let simd: SIMD3<Float>
    
    // MARK: - Initialization
    
    /// Initialize RealityKit vector with SIMD3<Float> components
    /// - Parameter simd: SIMD3<Float> vector for RealityKit scene operations
    init(simd: SIMD3<Float>) {
        self.simd = simd
    }
    
    /// Initialize from individual Float components
    /// - Parameters:
    ///   - x: X-component value (Float for RealityKit compatibility)
    ///   - y: Y-component value (Float for RealityKit compatibility)
    ///   - z: Z-component value (Float for RealityKit compatibility)
    init(x: Float, y: Float, z: Float) {
        self.simd = SIMD3<Float>(x, y, z)
    }
    
    /// Initialize from Double precision Vector3D
    /// Primary conversion method for orbital mechanics → RealityKit visualization
    /// - Parameter vector: High precision orbital mechanics vector to convert
    init(_ vector: Vector3D) {
        self.simd = SIMD3<Float>(Float(vector.x), Float(vector.y), Float(vector.z))
    }
    
    /// Initialize from Metal precision Vector3D_Metal
    /// Enables Metal → RealityKit data pipeline for GPU-calculated results
    /// - Parameter metalVector: Metal vector to convert for RealityKit display
    init(_ metalVector: Vector3D_Metal) {
        self.simd = SIMD3<Float>(metalVector.x, metalVector.y, metalVector.z)
    }
    
    // MARK: - Computed Properties
    
    /// X-component (Float for RealityKit compatibility)
    var x: Float {
        return simd.x
    }
    
    /// Y-component (Float for RealityKit compatibility)
    var y: Float {
        return simd.y
    }
    
    /// Z-component (Float for RealityKit compatibility)
    var z: Float {
        return simd.z
    }
    
    /// Vector magnitude (length) using SIMD operations
    /// Optimized for RealityKit 3D distance calculations
    var magnitude: Float {
        return length(simd)
    }
    
    /// Unit vector (normalized to magnitude 1) using SIMD operations
    /// Essential for RealityKit direction vectors and camera positioning
    var normalized: Vector3D_Reality {
        let mag = magnitude
        guard mag > 0 else { return Vector3D_Reality.zero }
        return Vector3D_Reality(simd: normalize(simd))
    }
    
    // MARK: - Static Constants
    
    /// Zero vector (origin) for RealityKit scene positioning
    static let zero = Vector3D_Reality(x: 0, y: 0, z: 0)
    
    /// Unit vector in X direction for RealityKit coordinate system
    static let unitX = Vector3D_Reality(x: 1, y: 0, z: 0)
    
    /// Unit vector in Y direction for RealityKit coordinate system
    static let unitY = Vector3D_Reality(x: 0, y: 1, z: 0)
    
    /// Unit vector in Z direction for RealityKit coordinate system
    static let unitZ = Vector3D_Reality(x: 0, y: 0, z: 1)
}

// MARK: - Vector Operations (RealityKit SIMD Precision)

extension Vector3D_Reality {
    
    /// Vector addition using SIMD operations (Float precision)
    /// Optimized for RealityKit 3D coordinate transformations
    static func + (lhs: Vector3D_Reality, rhs: Vector3D_Reality) -> Vector3D_Reality {
        return Vector3D_Reality(simd: lhs.simd + rhs.simd)
    }
    
    /// Vector subtraction using SIMD operations (Float precision)
    /// Essential for RealityKit relative positioning calculations
    static func - (lhs: Vector3D_Reality, rhs: Vector3D_Reality) -> Vector3D_Reality {
        return Vector3D_Reality(simd: lhs.simd - rhs.simd)
    }
    
    /// Scalar multiplication using SIMD operations (Float precision)
    /// Optimized for RealityKit scaling and coordinate transformations
    static func * (vector: Vector3D_Reality, scalar: Float) -> Vector3D_Reality {
        return Vector3D_Reality(simd: vector.simd * scalar)
    }
    
    /// Scalar multiplication (Float) - commutative using SIMD operations
    /// Provides natural mathematical notation for RealityKit calculations
    static func * (scalar: Float, vector: Vector3D_Reality) -> Vector3D_Reality {
        return vector * scalar
    }
    
    /// Scalar division using SIMD operations (Float precision)
    /// Essential for RealityKit coordinate system conversions
    static func / (vector: Vector3D_Reality, scalar: Float) -> Vector3D_Reality {
        return Vector3D_Reality(simd: vector.simd / scalar)
    }
    
    /// Dot product using SIMD components - Float precision
     /// Optimized for RealityKit angle calculations and projections
     func dot(_ other: Vector3D_Reality) -> Float {
         return simd.x * other.simd.x + simd.y * other.simd.y + simd.z * other.simd.z
     }
    
    /// Cross product using SIMD global functions - Float precision
    /// Essential for RealityKit coordinate system transformations and normal calculations
    func cross(_ other: Vector3D_Reality) -> Vector3D_Reality {
        return Vector3D_Reality(simd: simd_cross(self.simd, other.simd))
    }
}

// MARK: - Extension to Vector3D for RealityKit Conversion

extension Vector3D {
    
    /// RealityKit-compatible version with explicit type safety
    /// Primary interface for converting orbital mechanics calculations to visualization
    /// Usage: orbitalState.position.reality.simd → SIMD3<Float> for RealityKit
    var reality: Vector3D_Reality {
        return Vector3D_Reality(self)
    }
}


// MARK: - Codable Support

extension Vector3D: Codable {
    // Automatic Codable synthesis works for Double components
    // Enables JSON serialization for CE Agent integration
}

extension Vector3D_Metal: Codable {
    // Automatic Codable synthesis works for Float components
    // Enables Metal buffer serialization
}
