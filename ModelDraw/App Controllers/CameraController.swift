//
//  CameraController.swift
//  MissionViz
//
//  Adding Shift key monitoring for pivot gesture detection
//  Adapted from SimOrb's CameraGestureController pattern
//  Shift state updates ViewModel property to maintain reactive architecture
//

import Foundation
import SwiftUI
import AppKit
import RealityKit


// MARK: - Camera Configuration Enums

/// Camera mode for determining behavior type
/*enum CameraMode: CaseIterable {
    case sceneCenter    // Orbit around Earth/scene center for ECI missions
    case freeFlier     // CAD-like free movement anywhere in scene
} */

enum CameraMode: String, CaseIterable {
    case sceneCenter = "sceneCenter"
    case freeFlier = "freeFlier"
}

/// Camera configuration that includes target information
enum CameraConfiguration: Equatable {
    case sceneCenter                    // Orbit around scene origin
    case freeFlierMode                 // Free movement with no constraints
}




/// Professional camera controller for MissionViz 3D scene navigation
/// Handles reactive updates from ViewModel state changes and provides
/// CAD-style orbit/pan/zoom controls for spacecraft engineering analysis
/// Includes mouse scroll wheel support for universal input device compatibility
/// Enhanced with Shift key detection for pivot gesture support
class CameraController {
    
    // MARK: - Camera System Properties

    /// Primary perspective camera for orbital visualization
    private var primaryCamera: PerspectiveCamera?
    private var cameraDistance: Float = 10.0

    
    // MARK: - ViewModel Reference
    
    /// Reference to ViewModel for updating camera transform properties
    /// Enables reactive UI updates when camera position/rotation changes
    weak var viewModel: ViewModel?
    
    // MARK: - Gesture Sensitivity Settings
    
    /// Sensitivity multiplier for zoom gestures (adapted from SimOrb proven values)
    /// Reduced sensitivity for smooth, controllable zoom operations
    private let zoomSensitivity: Float = 0.005
    
    /// Sensitivity multiplier for scroll wheel zoom (matches SimOrb implementation)
    /// Used for mouse scroll wheel zoom calculations
    private let scrollSensitivity: Float = 0.01
    
    // MARK: - Event Monitoring (from SimOrb)
    
    /// NSEvent monitor for keyboard events (Shift key detection)
    /// Enables pivot gesture when Shift is held during drag operations
    private var keyboardMonitor: Any?
    
    /// NSEvent monitor for scroll wheel events (mouse zoom)
    /// Enables mouse scroll wheel zoom for users without trackpad
    private var scrollWheelMonitor: Any?
    

    // MARK: - Initialization and Cleanup
    
    /// Initialize camera controller with event monitoring
    /// Sets up both keyboard monitoring for Shift key and scroll wheel monitoring
    init() {
        setupEventMonitoring()
    }
    
    /// Clean up event monitors when controller is deallocated
    /// Prevents memory leaks and ensures proper resource management
    deinit {
        cleanup()
    }
    
    // MARK: - Event Monitoring Setup
    
    /// Setup system-level event monitoring for keyboard and mouse input
    /// Enables real-time Shift key detection and scroll wheel capture
    private func setupEventMonitoring() {
        setupKeyboardMonitoring()
        setupScrollWheelMonitoring()   // Now called conditionally from device callbacks
    }
    
    /// Setup keyboard monitoring for Shift key detection (adapted from SimOrb)
    /// Updates ViewModel.shiftPressed property to maintain reactive architecture
    private func setupKeyboardMonitoring() {
        // Monitor for Shift key press/release using NSEvent
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            DispatchQueue.main.async {
                // Update ViewModel property to maintain reactive architecture
                self?.viewModel?.shiftPressed = event.modifierFlags.contains(.shift)
            }
            return event
        }
        
        print("⌨️ CameraController: Keyboard monitoring active - Shift key detection enabled")
    }
    
    /// Setup scroll wheel monitoring for mouse zoom (existing method)
    /// Enables zoom gesture for mouse users (alternative to trackpad pinch)
    private func setupScrollWheelMonitoring() {
        // Monitor for scroll wheel events using NSEvent (matches SimOrb implementation)
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleScrollWheelZoom(deltaY: event.scrollingDeltaY)
            }
            return event
        }
        
        print("🖱️ CameraController: Mouse scroll wheel monitoring active - Zoom enabled")
    }
    
    /// Clean up event monitors (enhanced with keyboard monitor)
    /// Prevents memory leaks and ensures proper resource management
    private func cleanup() {
        if let keyboardMonitor = keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
            self.keyboardMonitor = nil
            print("⌨️ CameraController: Keyboard monitoring cleaned up")
        }
        
        if let scrollWheelMonitor = scrollWheelMonitor {
            NSEvent.removeMonitor(scrollWheelMonitor)
            self.scrollWheelMonitor = nil
            print("🖱️ CameraController: Scroll wheel monitoring cleaned up")
        }
    }

    
    // MARK: - Scroll Wheel Monitoring Control

    /// Enable scroll wheel monitoring when mouse is attached
    private func enableScrollWheelMonitoring() {
        // Don't create multiple monitors
        guard scrollWheelMonitor == nil else { return }
        
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleScrollWheelZoom(deltaY: event.scrollingDeltaY)
            }
            return event
        }
        
        print("🖱️ CameraController: Scroll wheel monitoring enabled")
    }

    /// Disable scroll wheel monitoring when mouse is detached
    private func disableScrollWheelMonitoring() {
        if let monitor = scrollWheelMonitor {
            NSEvent.removeMonitor(monitor)
            scrollWheelMonitor = nil
            print("🖱️ CameraController: Scroll wheel monitoring disabled")
        }
    }
    
    
    // MARK: - Computed Properties
     
     /// Current orbital angle in radians around Y-axis (horizontal rotation)
     /// Tracks how far around the circle we've rotated
     private var orbitalAngle: Float {
         get {
             // Extract angle from current ViewModel position using simple atan2
             guard let viewModel = viewModel else { return 0.0 }
             let pos = viewModel.cameraPosition
             return atan2(pos.x, pos.z)
         }
         set {
             updateSimpleOrbitPosition(angle: newValue)
         }
     }
    
    /// Current elevation angle in radians (vertical rotation around horizontal circle)
    /// Tracks camera height: 0 = equatorial plane, π/2 = north pole, -π/2 = south pole
    private var elevationAngle: Float {
        get {
            guard let viewModel = viewModel else { return 0.0 }
            let pos = viewModel.cameraPosition
            let distance = sqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z)
            return asin(pos.y / distance)
        }
        set {
            let currentOrbitalAngle = orbitalAngle
            //updateSphericalOrbitPosition(orbitalAngle: currentOrbitalAngle, elevationAngle: newValue)
        }
    }
    
    // MARK: - Camera Position Calculation Helpers

    /// Calculate orbital angle from camera position (replaces computed property)
    /// - Parameter position: Camera position in 3D space
    /// - Returns: Orbital angle in radians around Y-axis
    private func getOrbitalAngle(from position: SIMD3<Float>) -> Float {
        return atan2(position.x, position.z)
    }

    /// Calculate elevation angle from camera position (replaces computed property)
    /// - Parameter position: Camera position in 3D space
    /// - Returns: Elevation angle in radians (0 = equatorial, π/2 = north pole)
    private func getElevationAngle(from position: SIMD3<Float>) -> Float {
        let distance = sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
        return asin(position.y / distance)
    }
    
    
    // MARK: - Configuration Method
    
    /// Configure camera behavior based on ViewModel state changes
    /// Called from RealityView update block when ViewModel.cameraConfiguration changes
    /// Updates ViewModel camera transform properties to trigger reactive UI updates
    /// - Parameter configuration: Current camera configuration from ViewModel
    func configure(for configuration: CameraConfiguration) {
        guard let viewModel = viewModel else {
            print("⚠️ CameraController: No ViewModel reference available")
            return
        }
        
        switch configuration {
        case .sceneCenter:
            // ECI/near-Earth missions: camera orbits around scene origin
            print("📷 CameraController: Configuring for scene center mode")
            
            // Set camera to orbit around origin with appropriate distance
            // note that sceneCenter camera ALWAYS points at [0,0,0]
            viewModel.cameraPosition = [-8.0, 5, 0]  // Camera at -X axis
            //viewModel.cameraRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
            // for a camera facing AWAY from the vernal equinox, use the following
            //viewModel.cameraPosition = [4.0, 0, 0]  // Camera at +X axis
            viewModel.cameraDistance = 4.0
            
        case .freeFlierMode:
            // CAD-like free camera: can be positioned anywhere with any orientation
            print("📷 CameraController: Configuring for freeFlier mode")
                        
            // Initialize to a good starting position facing the veral equinox
            viewModel.cameraPosition = [-6.0, 0, 0]  // Camera at -X axis
            viewModel.cameraRotation = simd_quatf(angle: -Float.pi/2, axis: [0, 1, 0])  // -90° Y rotation
            // for a camera facing AWAY from the vernal equinox, use the following
            //viewModel.cameraPosition = [15.0, 0, 0]  // Camera at -X axis
            //viewModel.cameraRotation = simd_quatf(angle: Float.pi/2, axis: [0, 1, 0])  // 90° Y rotation
            viewModel.cameraDistance = 6.0  // Distance used for zoom calculations
        }
    }
    
    
    // MARK: - FreeFlier Camera Gesture Handler
        
        /// Handle freeFlier camera translation for world-relative movement
        /// Normal drag in freeFlier mode moves camera position along world axes
        /// - Parameter translation: 2D drag translation from SwiftUI DragGesture
        func handleFreeFlierTranslateGesture(translation: CGSize) {
            guard let viewModel = viewModel else {
                print("⚠️ CameraController.handleFreeFlierTranslateGesture: No ViewModel reference available")
                return
            }
            
            // Use same base sensitivity as other gestures for consistency
            let translateSensitivity: Float = 0.0005  // Slightly higher for noticeable movement
            
            // Calculate translation deltas along world axes
            // Drag left/right = move along world X-axis
            // Drag up/down = move along world Y-axis (up = positive Y)
            let deltaX = Float(translation.width) * translateSensitivity
            let deltaY = -Float(translation.height) * translateSensitivity  // Invert Y for natural feel
            
            // Get current camera position and apply world-relative translation
            let currentPosition = viewModel.cameraPosition
            let newPosition = SIMD3<Float>(
                currentPosition.x + deltaX,     // X: left/right movement
                currentPosition.y + deltaY,     // Y: up/down movement
                currentPosition.z               // Z: unchanged by normal drag
            )
            
            // Update ViewModel with new camera position
            viewModel.cameraPosition = newPosition
            
            print("🎮 FreeFlier translate: deltaX=\(deltaX), deltaY=\(deltaY)")
            print("🎮 New position: \(newPosition)")
        }
    
    
    
    // MARK: - Simple Orbit Gesture Handler
    
    /// Handle orbit gesture using simple circular motion and built-in look() method
    /// Much simpler than complex spherical coordinates - just move in a circle
    /// Uses proven SimOrb sensitivity for smooth control
    /// - Parameter translation: 2D drag translation from SwiftUI DragGesture
    /*func handleSimpleOrbitGesture(translation: CGSize) {
        guard let viewModel = viewModel else {
            print("⚠️ CameraController.handleSimpleOrbitGesture: No ViewModel reference available")
            return
        }
        
        // Use proven SimOrb sensitivity scaling for smooth control
        let orbitSensitivity: Float = 0.001  // Matches SimOrb proven values
        
        // Calculate angle change from horizontal drag
        let angleChange = Float(translation.width) * orbitSensitivity
        
        // Update orbital angle (adding to current angle for continuous rotation)
        let newAngle = orbitalAngle + angleChange
        
        // Update camera position using simple circular motion
        updateSimpleOrbitPosition(angle: newAngle)
        
        print("🎮 Simple orbit: angle=\(newAngle), distance=\(viewModel.cameraDistance)")
    } */
    
    /// Handle orbit gesture with full 3D capability for GMST validation
    /// Horizontal drag = orbital angle around Y-axis (existing behavior)
    /// Vertical drag = elevation angle for overhead/underside views (NEW)
    /// - Parameter translation: 2D drag translation from SwiftUI DragGesture
    /*func handleSimpleOrbitGesture(translation: CGSize, camera: PerspectiveCamera) {
    //func handleSimpleOrbitGesture(translation: CGSize) {
        guard let viewModel = viewModel else {
            print("⚠️ CameraController.handleSimpleOrbitGesture: No ViewModel reference available")
            return
        }
        
        // Use proven SimOrb sensitivity scaling for smooth control
        let orbitSensitivity: Float = 0.001  // Matches SimOrb proven values
        let elevationSensitivity: Float = 0.001  // Same sensitivity for vertical movement
        
        // Calculate angle changes from drag translation
        let orbitalAngleChange = Float(translation.width) * orbitSensitivity
        let elevationAngleChange = -Float(translation.height) * elevationSensitivity  // Invert for natural feel
        
        // Update both angles from current position
        let newOrbitalAngle = orbitalAngle + orbitalAngleChange
        let newElevationAngle = max(-Float.pi/2 + 0.1, min(Float.pi/2 - 0.1, elevationAngle + elevationAngleChange))  // Clamp to prevent gimbal lock
        
        // Update camera position using spherical coordinates
        updateSphericalOrbitPosition(orbitalAngle: newOrbitalAngle, elevationAngle: newElevationAngle)
        
        print("🎮 3D orbit: orbital=\(newOrbitalAngle), elevation=\(newElevationAngle), distance=\(viewModel.cameraDistance)")
    } */
    
    /// Handle orbit gesture for camera rotation around scene center
    /// Migrated to Entity.Observable - directly updates camera Entity instead of ViewModel
    /// Horizontal drag = orbital angle around Y-axis, Vertical drag = elevation angle
    /// - Parameters:
    ///   - translation: 2D drag translation from SwiftUI DragGesture
    ///   - camera: PerspectiveCamera to update directly via Entity.Observable
    func handleSimpleOrbitGesture(translation: CGSize, camera: PerspectiveCamera) {
        // Use proven SimOrb sensitivity scaling for smooth control
        let orbitSensitivity: Float = 0.001  // Matches SimOrb proven values
        let elevationSensitivity: Float = 0.001  // Same sensitivity for vertical movement
        
        // Calculate angle changes from drag translation
        let orbitalAngleChange = Float(translation.width) * orbitSensitivity
        let elevationAngleChange = -Float(translation.height) * elevationSensitivity  // Invert for natural feel
        
        // Get current angles from camera position (Entity.Observable source)
        let currentOrbitalAngle = getOrbitalAngle(from: camera.position)
        let currentElevationAngle = getElevationAngle(from: camera.position)
        
        // Update both angles from current position
        let newOrbitalAngle = currentOrbitalAngle + orbitalAngleChange
        let newElevationAngle = max(-Float.pi/2 + 0.1, min(Float.pi/2 - 0.1, currentElevationAngle + elevationAngleChange))  // Clamp to prevent gimbal lock
        
        // Calculate new camera position using spherical coordinates
        let cosElevation = cos(newElevationAngle)
        let sinElevation = sin(newElevationAngle)
        
        let newPosition = SIMD3<Float>(
            cameraDistance * cosElevation * sin(newOrbitalAngle),    // X position
            cameraDistance * sinElevation,                           // Y position
            cameraDistance * cosElevation * cos(newOrbitalAngle)     // Z position
        )
        
        // Direct Entity.Observable update - SwiftUI automatically observes changes
        camera.position = newPosition
        
        print("🎮 3D orbit: orbital=\(newOrbitalAngle), elevation=\(newElevationAngle), distance=\(cameraDistance)")
    }
    
    // MARK: - Zoom Gesture Handlers
    
    /// Handle zoom gesture for camera distance adjustment (trackpad pinch)
    /// Updates camera distance while maintaining current orbital position
    /// FIXED: Now preserves both orbital and elevation angles during zoom
    /// - Parameters:
    ///   - zoomFactor: Zoom multiplier (>1.0 = zoom in, <1.0 = zoom out)
    ///   - camera: PerspectiveCamera to update directly via Entity.Observable
    func handleZoomGesture(zoomFactor: Float, camera: PerspectiveCamera) {
        // Apply zoom limits to prevent camera going too close or too far
        // Reasonable limits for spacecraft mission visualization
        guard zoomFactor > 0.1 && zoomFactor < 10.0 else {
            print("🔍 Zoom factor \(zoomFactor) outside safe limits, ignoring")
            return
        }
        
        // Calculate new distance by applying zoom factor to current distance
        // Division by factor: factor > 1.0 = zoom in (closer), factor < 1.0 = zoom out (farther)
        let currentDistance = cameraDistance  // Use local property
        let newDistance = max(1.0, min(50.0, currentDistance / zoomFactor))  // Enforce distance bounds
        
        // Update local distance for orbit radius tracking
        cameraDistance = newDistance
        
        // Calculate new position preserving both orbital AND elevation angles
        let currentOrbitalAngle = getOrbitalAngle(from: camera.position)
        let currentElevationAngle = getElevationAngle(from: camera.position)
        
        // Calculate new camera position using spherical coordinates
        let cosElevation = cos(currentElevationAngle)
        let sinElevation = sin(currentElevationAngle)
        
        let newPosition = SIMD3<Float>(
            newDistance * cosElevation * sin(currentOrbitalAngle),    // X position
            newDistance * sinElevation,                               // Y position
            newDistance * cosElevation * cos(currentOrbitalAngle)     // Z position
        )
        
        // Direct Entity.Observable update
        camera.position = newPosition
        
        print("🔍 Zoom applied: factor=\(zoomFactor), oldDistance=\(currentDistance), newDistance=\(newDistance)")
        print("🔍 Position preserved: orbital=\(currentOrbitalAngle), elevation=\(currentElevationAngle)")
    }
    
    /// Handle zoom gesture for camera distance adjustment (trackpad pinch)
    /// Updates camera distance while maintaining current orbital position
    /// FIXED: Now preserves both orbital and elevation angles during zoom
    /// - Parameter zoomFactor: Zoom multiplier (>1.0 = zoom in, <1.0 = zoom out)
    /*func handleZoomGesture(zoomFactor: Float) {
        guard let viewModel = viewModel else {
            print("⚠️ CameraController.handleZoomGesture: No ViewModel reference available")
            return
        }
        
        // Apply zoom limits to prevent camera going too close or too far
        // Reasonable limits for spacecraft mission visualization
        guard zoomFactor > 0.1 && zoomFactor < 10.0 else {
            print("🔍 Zoom factor \(zoomFactor) outside safe limits, ignoring")
            return
        }
        
        // Calculate new distance by applying zoom factor to current distance
        // Division by factor: factor > 1.0 = zoom in (closer), factor < 1.0 = zoom out (farther)
        let currentDistance = viewModel.cameraDistance
        let newDistance = max(1.0, min(50.0, currentDistance / zoomFactor))  // Enforce distance bounds
        
        // Update ViewModel distance for orbit radius tracking
        viewModel.cameraDistance = newDistance
        
        // FIXED: Preserve both orbital AND elevation angles during zoom
        // OLD (problematic): let currentAngle = orbitalAngle
        // OLD (problematic): updateSimpleOrbitPosition(angle: currentAngle)
        
        // NEW: Maintain current 3D position during zoom
        let currentOrbitalAngle = orbitalAngle
        let currentElevationAngle = elevationAngle  // Preserve elevation for overhead views!
        updateSphericalOrbitPosition(orbitalAngle: currentOrbitalAngle, elevationAngle: currentElevationAngle)
        
        print("🔍 Zoom applied: factor=\(zoomFactor), oldDistance=\(currentDistance), newDistance=\(newDistance)")
        print("🔍 Position preserved: orbital=\(currentOrbitalAngle), elevation=\(currentElevationAngle)")
    } */

    /// Handle scroll wheel zoom events for mouse users
    /// - Parameter deltaY: Scroll wheel delta (positive = zoom in, negative = zoom out)
    private func handleScrollWheelZoom(deltaY: CGFloat) {
        guard let viewModel = viewModel else { return }
        
        // Convert scroll delta to zoom factor using sensitivity
        let zoomFactor = 1.0 + Float(deltaY) * scrollSensitivity
        
        // Apply same zoom limits as gesture zoom
        guard zoomFactor > 0.1 && zoomFactor < 10.0 else { return }
        
        // Calculate new distance
        let currentDistance = viewModel.cameraDistance
        let newDistance = max(1.0, min(50.0, currentDistance / zoomFactor))
        
        // Update distance
        viewModel.cameraDistance = newDistance
        
        // FIXED: Preserve both angles during scroll zoom too
        let currentOrbitalAngle = orbitalAngle
        let currentElevationAngle = elevationAngle
        
        updateSphericalOrbitPosition(orbitalAngle: currentOrbitalAngle, elevationAngle: currentElevationAngle)
        
        print("🖱️ Scroll zoom: deltaY=\(deltaY), newDistance=\(newDistance)")
    }
    
    /// Apply zoom factor to camera distance (shared logic for trackpad and mouse)
    /// Maintains orbital angle while adjusting distance for consistent zoom behavior
    /// - Parameter zoomFactor: Zoom multiplication factor (>1.0 = zoom in, <1.0 = zoom out)
    private func applyZoomFactor(_ zoomFactor: Float) {
        guard let viewModel = viewModel else { return }
        
        // Apply zoom limits to prevent camera going too close or too far
        // Reasonable limits for spacecraft mission visualization
        guard zoomFactor > 0.1 && zoomFactor < 10.0 else {
            print("🔍 Zoom factor \(zoomFactor) outside safe limits, ignoring")
            return
        }
        
        // Calculate new distance by applying zoom factor to current distance
        // Division by factor: factor > 1.0 = zoom in (closer), factor < 1.0 = zoom out (farther)
        let currentDistance = viewModel.cameraDistance
        let newDistance = max(1.0, min(50.0, currentDistance / zoomFactor))  // Enforce distance bounds
        
        // Update ViewModel distance for orbit radius tracking
        viewModel.cameraDistance = newDistance
        
        // Update camera position maintaining current orbital angle but new distance
        let currentAngle = orbitalAngle
        updateSimpleOrbitPosition(angle: currentAngle)
        
        print("🔍 Zoom applied: factor=\(zoomFactor), oldDistance=\(currentDistance), newDistance=\(newDistance)")
    }
    
    
    // MARK: - Camera Position Updates
    
    /// Legacy simple orbit position update (DEPRECATED - use spherical version)
    /// Kept for compatibility but now delegates to spherical method with elevation=0
    /// - Parameter angle: New orbital angle in radians around Y-axis
    private func updateSimpleOrbitPosition(angle: Float) {
        // Delegate to spherical method with zero elevation for backward compatibility
        updateSphericalOrbitPosition(orbitalAngle: angle, elevationAngle: 0.0)
    }
    
    
    /// Update camera position using full spherical coordinates for 3D orbit
    /// Replaces the limited updateSimpleOrbitPosition for GMST validation capability
    /// - Parameters:
    ///   - orbitalAngle: Horizontal angle in radians around Y-axis (0 = +Z direction)
    ///   - elevationAngle: Vertical angle in radians (0 = equatorial, π/2 = north pole)
    /*private func updateSphericalOrbitPosition(orbitalAngle: Float, elevationAngle: Float) {
        guard let viewModel = viewModel else { return }
        
        let distance = viewModel.cameraDistance
        
        // Convert spherical coordinates to Cartesian
        // Orbital angle rotates around Y-axis, elevation angle lifts from equatorial plane
        let cosElevation = cos(elevationAngle)
        let sinElevation = sin(elevationAngle)
        
        let newPosition = SIMD3<Float>(
            distance * cosElevation * sin(orbitalAngle),    // X position
            distance * sinElevation,                        // Y position (NEW: allows overhead views)
            distance * cosElevation * cos(orbitalAngle)     // Z position
        )
        
        viewModel.cameraPosition = newPosition
        print("🎮 Spherical camera position: orbital=\(orbitalAngle)°, elevation=\(elevationAngle)°, pos=\(newPosition)")
    } */
    
    
    // MARK: - Camera Pivot Gesture Handler
        
        /// Handle camera pivot gesture for free-look rotation around current position
        /// Camera stays in same location but rotates to look in different directions
        /// Uses same sensitivity as orbit gesture for consistent control feel
        /// - Parameter translation: 2D drag translation from SwiftUI DragGesture
        func handleCameraPivotGesture(translation: CGSize) {
            guard let viewModel = viewModel else {
                print("⚠️ CameraController.handleCameraPivotGesture: No ViewModel reference available")
                return
            }
            
            // Use same sensitivity as orbit for consistent feel
            let horizontalSensitivity: Float = 0.00004  // based on feel tests
            let verticalSensitivity: Float = 0.00003  // based on feel tests

            // Extract horizontal and vertical rotation deltas from mouse movement
            let horizontalDelta = Float(translation.width) * horizontalSensitivity
            let verticalDelta = Float(translation.height) * verticalSensitivity
            
            // Get current camera rotation quaternion from ViewModel
            let currentRotation = viewModel.cameraRotation
            
            // Create horizontal rotation (yaw) around world Y-axis
            // Positive horizontalDelta = rotate left, negative = rotate right
            let yawRotation = simd_quatf(angle: -horizontalDelta, axis: SIMD3<Float>(0, 1, 0))
            
            // Create vertical rotation (pitch) around camera's local X-axis
            // Positive verticalDelta = rotate down, negative = rotate up
            let pitchRotation = simd_quatf(angle: verticalDelta, axis: SIMD3<Float>(1, 0, 0))
            
            // Apply rotations: first pitch (local), then yaw (world)
            // Order matters for proper free-look behavior
            let newRotation = yawRotation * currentRotation * pitchRotation
            
            // Update ViewModel with new camera rotation
            viewModel.cameraRotation = newRotation
            
            print("🎮 Camera pivot: yaw=\(horizontalDelta), pitch=\(verticalDelta)")
            print("🎮 New rotation: \(newRotation)")
            
            // Note: Camera position stays unchanged - only rotation changes
            // The RealityView update block will apply this rotation via camera.look()
        }
    
    
    // MARK: - Ray Casting for Drag-and-Drop

    /// Cast a ray from cursor position to Y=0 plane intersection for precise object placement
    /// Returns world position clamped to engineering grid bounds (-10m to +10m on X-Z plane)
    /// - Parameters:
    ///   - screenPoint: Cursor position in screen coordinates
    ///   - viewSize: Size of the RealityView for coordinate conversion
    /// - Returns: World position on Y=0 plane, clamped to grid bounds
    func worldPositionFromCursor(_ screenPoint: CGPoint, viewSize: CGSize) -> SIMD3<Float> {
        guard let viewModel = viewModel else {
            print("⚠️ CameraController.worldPositionFromCursor: No ViewModel reference, returning origin")
            return SIMD3<Float>(0, 0, 0)
        }
        
        // Convert screen coordinates to normalized device coordinates (-1 to 1)
        let normalizedX = (2.0 * Float(screenPoint.x) / Float(viewSize.width)) - 1.0
        let normalizedY = 1.0 - (2.0 * Float(screenPoint.y) / Float(viewSize.height))  // Flip Y
        
        // Get camera position and create ray direction based on camera mode
        let cameraPosition = viewModel.cameraPosition
        let rayDirection: SIMD3<Float>
        
        switch viewModel.cameraMode {
        case .sceneCenter:
            // Scene center mode: camera always looks at origin
            // Ray direction needs to account for perspective and cursor offset
            let lookDirection = normalize(-cameraPosition)  // Look toward origin
            
            // Create right and up vectors for camera's local coordinate system
            let worldUp = SIMD3<Float>(0, 1, 0)
            let rightVector = normalize(cross(lookDirection, worldUp))
            let upVector = cross(rightVector, lookDirection)
            
            // Apply field of view for perspective (assuming ~60° FOV)
            let fovFactor: Float = tan(30.0 * Float.pi / 180.0)  // Half of 60° FOV
            let aspectRatio = Float(viewSize.width) / Float(viewSize.height)
            
            // Calculate ray direction with perspective offset
            rayDirection = normalize(
                lookDirection +
                rightVector * (normalizedX * fovFactor * aspectRatio) +
                upVector * (normalizedY * fovFactor)
            )
            
        case .freeFlier:
            // Free flier mode: use camera rotation to determine look direction
            let baseDirection = SIMD3<Float>(0, 0, -1)  // Forward in camera space
            let lookDirection = viewModel.cameraRotation.act(baseDirection)
            
            // Create camera's local coordinate system
            let rightVector = normalize(viewModel.cameraRotation.act(SIMD3<Float>(1, 0, 0)))
            let upVector = normalize(viewModel.cameraRotation.act(SIMD3<Float>(0, 1, 0)))
            
            // Apply field of view for perspective
            let fovFactor: Float = tan(30.0 * Float.pi / 180.0)
            let aspectRatio = Float(viewSize.width) / Float(viewSize.height)
            
            rayDirection = normalize(
                lookDirection +
                rightVector * (normalizedX * fovFactor * aspectRatio) +
                upVector * (normalizedY * fovFactor)
            )
        }
        
        // Calculate intersection with Y=0 plane
        let intersectionPoint: SIMD3<Float>
        
        if abs(rayDirection.y) > 0.001 {  // Ray is not parallel to Y=0 plane
            // Ray equation: point = cameraPosition + t * rayDirection
            // For Y=0 plane: cameraPosition.y + t * rayDirection.y = 0
            let t = -cameraPosition.y / rayDirection.y
            
            if t > 0 {  // Intersection is in front of camera
                intersectionPoint = cameraPosition + t * rayDirection
            } else {
                // Ray points away from plane, use fallback
                intersectionPoint = projectToPlaneAtDistance(cameraPosition: cameraPosition, rayDirection: rayDirection)
            }
        } else {
            // Ray is parallel to Y=0 plane, use fallback
            intersectionPoint = projectToPlaneAtDistance(cameraPosition: cameraPosition, rayDirection: rayDirection)
        }
        
        // Clamp to engineering grid bounds (-10m to +10m on X and Z axes)
        let gridBounds: Float = 10.0
        let clampedPosition = SIMD3<Float>(
            max(-gridBounds, min(gridBounds, intersectionPoint.x)),  // X: -10 to +10
            0.0,  // Y: always on the ground plane
            max(-gridBounds, min(gridBounds, intersectionPoint.z))   // Z: -10 to +10
        )
        
        print("🎯 Ray cast: screen(\(screenPoint.x), \(screenPoint.y)) → world(\(clampedPosition.x), \(clampedPosition.y), \(clampedPosition.z))")
        
        return clampedPosition
    }

    /// Fallback projection for edge cases where ray doesn't intersect Y=0 plane
    /// Projects forward from camera at current distance, then drops to Y=0 plane
    private func projectToPlaneAtDistance(cameraPosition: SIMD3<Float>, rayDirection: SIMD3<Float>) -> SIMD3<Float> {
        guard let viewModel = viewModel else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        // Project forward by camera distance
        let projectedPoint = cameraPosition + rayDirection * viewModel.cameraDistance
        
        // Drop to Y=0 plane
        return SIMD3<Float>(projectedPoint.x, 0.0, projectedPoint.z)
    }
    
    
}
