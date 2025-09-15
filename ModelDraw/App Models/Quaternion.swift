//
//  Quaternion.swift
//  SimOrb
//
//  Pure mathematical quaternion type for spacecraft attitude representation
//  Follows Vector3D pattern with Double precision internally, Float access for Metal/RealityKit
//  Convention A: w (scalar), x, y, z (vector components)
//

import Foundation
import simd

/// A pure mathematical quaternion type for representing rotations in 3D space
/// Stores components as Double precision for orbital mechanics accuracy
/// Provides Float access for Metal/RealityKit compatibility
struct Quaternion {
    
    // MARK: - Storage (Double precision for accuracy)
    
    /// Scalar component (real part)
    let w: Double
    
    /// Vector component i (imaginary i coefficient)
    let x: Double
    
    /// Vector component j (imaginary j coefficient)
    let y: Double
    
    /// Vector component k (imaginary k coefficient)
    let z: Double
    
    // MARK: - Initializers
    
    /// Create quaternion from individual components
    /// - Parameters:
    ///   - w: Scalar component (real part)
    ///   - x: Vector i component
    ///   - y: Vector j component
    ///   - z: Vector k component
    init(w: Double, x: Double, y: Double, z: Double) {
        self.w = w
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Create quaternion from simd_quatf (RealityKit/Metal)
    /// - Parameter simdQuat: simd quaternion to convert
    init(_ simdQuat: simd_quatf) {
        // simd_quatf uses (ix, iy, iz, r) ordering
        self.w = Double(simdQuat.real)
        self.x = Double(simdQuat.imag.x)
        self.y = Double(simdQuat.imag.y)
        self.z = Double(simdQuat.imag.z)
    }
    
    /// Create quaternion from simd_quatd (high precision)
    /// - Parameter simdQuat: simd quaternion to convert
    init(_ simdQuat: simd_quatd) {
        self.w = simdQuat.real
        self.x = simdQuat.imag.x
        self.y = simdQuat.imag.y
        self.z = simdQuat.imag.z
    }
    
    // MARK: - Float Access (for Metal/RealityKit)
    
    /// Scalar component as Float
    var wf: Float { Float(w) }
    
    /// Vector i component as Float
    var xf: Float { Float(x) }
    
    /// Vector j component as Float
    var yf: Float { Float(y) }
    
    /// Vector k component as Float
    var zf: Float { Float(z) }
    
    // MARK: - Conversions
    
    /// Convert to simd_quatf for RealityKit/Metal usage
    var simd: simd_quatf {
        simd_quatf(ix: xf, iy: yf, iz: zf, r: wf)
    }
    
    /// Convert to simd_quatd for high precision calculations
    var simdDouble: simd_quatd {
        simd_quatd(ix: x, iy: y, iz: z, r: w)
    }
    
    // MARK: - Common Quaternions
    
    /// Identity quaternion (no rotation)
    static let identity = Quaternion(w: 1.0, x: 0.0, y: 0.0, z: 0.0)
    
    // MARK: - Properties
    
    /// Magnitude (norm) of the quaternion
    var magnitude: Double {
        sqrt(w*w + x*x + y*y + z*z)
    }
    
    /// Magnitude squared (more efficient than magnitude)
    var magnitudeSquared: Double {
        w*w + x*x + y*y + z*z
    }
    
    /// Returns true if this is approximately a unit quaternion
    var isUnit: Bool {
        abs(magnitudeSquared - 1.0) < 1e-10
    }
    
    /// Normalized (unit) quaternion
    var normalized: Quaternion {
        let mag = magnitude
        guard mag > 0 else { return .identity }
        return Quaternion(w: w/mag, x: x/mag, y: y/mag, z: z/mag)
    }
    
    /// Conjugate quaternion
    var conjugate: Quaternion {
        Quaternion(w: w, x: -x, y: -y, z: -z)
    }
    
    /// Inverse quaternion (for unit quaternions, this is the conjugate)
    var inverse: Quaternion {
        let magSq = magnitudeSquared
        return Quaternion(w: w/magSq, x: -x/magSq, y: -y/magSq, z: -z/magSq)
    }
}

// MARK: - Equatable

extension Quaternion: Equatable {
    static func == (lhs: Quaternion, rhs: Quaternion) -> Bool {
        return abs(lhs.w - rhs.w) < 1e-15 &&
               abs(lhs.x - rhs.x) < 1e-15 &&
               abs(lhs.y - rhs.y) < 1e-15 &&
               abs(lhs.z - rhs.z) < 1e-15
    }
}

// MARK: - CustomStringConvertible

extension Quaternion: CustomStringConvertible {
    var description: String {
        "Quaternion(w: \(w), x: \(x), y: \(y), z: \(z))"
    }
}

// MARK: - Mathematical Operations

extension Quaternion {
    
    /// Quaternion multiplication
    /// - Parameters:
    ///   - lhs: Left quaternion
    ///   - rhs: Right quaternion
    /// - Returns: Product quaternion
    static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w
        )
    }
    
    /// Scalar multiplication
    /// - Parameters:
    ///   - quaternion: Quaternion to scale
    ///   - scalar: Scalar value
    /// - Returns: Scaled quaternion
    static func * (quaternion: Quaternion, scalar: Double) -> Quaternion {
        return Quaternion(w: quaternion.w * scalar,
                         x: quaternion.x * scalar,
                         y: quaternion.y * scalar,
                         z: quaternion.z * scalar)
    }
    
    /// Scalar multiplication (commutative)
    static func * (scalar: Double, quaternion: Quaternion) -> Quaternion {
        return quaternion * scalar
    }
    
    /// Quaternion addition
    static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(w: lhs.w + rhs.w,
                         x: lhs.x + rhs.x,
                         y: lhs.y + rhs.y,
                         z: lhs.z + rhs.z)
    }
    
    /// Quaternion subtraction
    static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(w: lhs.w - rhs.w,
                         x: lhs.x - rhs.x,
                         y: lhs.y - rhs.y,
                         z: lhs.z - rhs.z)
    }
    
    /// Rotate a vector by this quaternion
    /// Uses the standard quaternion rotation formula: q * v * q*
    /// - Parameter vector: Vector3D to rotate
    /// - Returns: Rotated Vector3D
    func rotate(_ vector: Vector3D) -> Vector3D {
        // Convert vector to pure quaternion (w=0, xyz=vector)
        let vectorQuat = Quaternion(w: 0, x: vector.x, y: vector.y, z: vector.z)
        
        // Apply rotation: result = q * v * q*
        let rotatedQuat = self * vectorQuat * self.conjugate
        
        // Extract vector part (ignore w component which should be ~0)
        return Vector3D(x: rotatedQuat.x, y: rotatedQuat.y, z: rotatedQuat.z)
    }
    
    
    /// Create quaternion from axis-angle representation
    /// - Parameters:
    ///   - axis: Rotation axis (will be normalized)
    ///   - angle: Rotation angle in radians
    /// - Returns: Quaternion representing the rotation
    static func from(axis: Vector3D, angle: Double) -> Quaternion {
        let normalizedAxis = axis.normalized
        let halfAngle = angle * 0.5
        let sinHalf = sin(halfAngle)
        
        return Quaternion(
            w: cos(halfAngle),
            x: normalizedAxis.x * sinHalf,
            y: normalizedAxis.y * sinHalf,
            z: normalizedAxis.z * sinHalf
        )
    }
    
    /// Create quaternion representing rotation from one vector to another
    /// - Parameters:
    ///   - from: Starting vector
    ///   - to: Target vector
    /// - Returns: Quaternion representing the rotation
    static func from(from: Vector3D, to: Vector3D) -> Quaternion {
        let fromNorm = from.normalized
        let toNorm = to.normalized
        
        let dot = fromNorm.dot(toNorm)
        
        // Vectors are already aligned
        if dot >= 0.999999 {
            return .identity
        }
        
        // Vectors are opposite
        if dot <= -0.999999 {
            // Find any perpendicular vector
            let perpendicular = abs(fromNorm.x) < 0.9 ?
            Vector3D(x: 1, y: 0, z: 0) :
            Vector3D(x: 0, y: 1, z: 0)
            let axis = fromNorm.cross(perpendicular).normalized
            return Quaternion.from(axis: axis, angle: Double.pi)
        }
        
        // General case
        let cross = fromNorm.cross(toNorm)
        let w = sqrt((1 + dot) * 0.5)
        let invW = 1.0 / (2.0 * w)
        
        return Quaternion(
            w: w,
            x: cross.x * invW,
            y: cross.y * invW,
            z: cross.z * invW
        )
    }
}
