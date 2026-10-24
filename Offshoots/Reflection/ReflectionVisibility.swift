enum ReflectionVisibility {
    static func showEntry(gate: ReflectionSurfaceState, savedCount: Int) -> Bool {
        savedCount > 0 || gate != .hidden
    }
}
