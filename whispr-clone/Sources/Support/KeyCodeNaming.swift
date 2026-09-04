import Carbon.HIToolbox

/// Human-readable names for the key codes we expect someone to actually
/// bind push-to-talk to. Falls back to a raw code for anything exotic.
enum KeyCodeNaming {
    private static let names: [UInt16: String] = [
        UInt16(kVK_RightOption): "Right Option",
        UInt16(kVK_Option): "Left Option",
        UInt16(kVK_RightCommand): "Right Command",
        UInt16(kVK_Command): "Left Command",
        UInt16(kVK_RightControl): "Right Control",
        UInt16(kVK_Control): "Left Control",
        UInt16(kVK_RightShift): "Right Shift",
        UInt16(kVK_Shift): "Left Shift",
        UInt16(kVK_Function): "Fn",
        UInt16(kVK_F13): "F13",
        UInt16(kVK_F14): "F14",
        UInt16(kVK_F15): "F15",
        UInt16(kVK_CapsLock): "Caps Lock",
    ]

    static func displayName(for keyCode: UInt16) -> String {
        names[keyCode] ?? "Key code \(keyCode)"
    }
}
