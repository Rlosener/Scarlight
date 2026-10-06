import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "dice_anal" asset catalog image resource.
    static let diceAnal = DeveloperToolsSupport.ImageResource(name: "dice_anal", bundle: resourceBundle)

    /// The "dice_back" asset catalog image resource.
    static let diceBack = DeveloperToolsSupport.ImageResource(name: "dice_back", bundle: resourceBundle)

    /// The "dice_cowgirl" asset catalog image resource.
    static let diceCowgirl = DeveloperToolsSupport.ImageResource(name: "dice_cowgirl", bundle: resourceBundle)

    /// The "dice_dog" asset catalog image resource.
    static let diceDog = DeveloperToolsSupport.ImageResource(name: "dice_dog", bundle: resourceBundle)

    /// The "dice_doggy" asset catalog image resource.
    static let diceDoggy = DeveloperToolsSupport.ImageResource(name: "dice_doggy", bundle: resourceBundle)

    /// The "dice_front" asset catalog image resource.
    static let diceFront = DeveloperToolsSupport.ImageResource(name: "dice_front", bundle: resourceBundle)

    /// The "dice_licking" asset catalog image resource.
    static let diceLicking = DeveloperToolsSupport.ImageResource(name: "dice_licking", bundle: resourceBundle)

    /// The "dice_oral" asset catalog image resource.
    static let diceOral = DeveloperToolsSupport.ImageResource(name: "dice_oral", bundle: resourceBundle)

    /// The "dice_sex" asset catalog image resource.
    static let diceSex = DeveloperToolsSupport.ImageResource(name: "dice_sex", bundle: resourceBundle)

    /// The "dice_standing" asset catalog image resource.
    static let diceStanding = DeveloperToolsSupport.ImageResource(name: "dice_standing", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "dice_anal" asset catalog image.
    static var diceAnal: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceAnal)
#else
        .init()
#endif
    }

    /// The "dice_back" asset catalog image.
    static var diceBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceBack)
#else
        .init()
#endif
    }

    /// The "dice_cowgirl" asset catalog image.
    static var diceCowgirl: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceCowgirl)
#else
        .init()
#endif
    }

    /// The "dice_dog" asset catalog image.
    static var diceDog: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceDog)
#else
        .init()
#endif
    }

    /// The "dice_doggy" asset catalog image.
    static var diceDoggy: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceDoggy)
#else
        .init()
#endif
    }

    /// The "dice_front" asset catalog image.
    static var diceFront: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceFront)
#else
        .init()
#endif
    }

    /// The "dice_licking" asset catalog image.
    static var diceLicking: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceLicking)
#else
        .init()
#endif
    }

    /// The "dice_oral" asset catalog image.
    static var diceOral: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceOral)
#else
        .init()
#endif
    }

    /// The "dice_sex" asset catalog image.
    static var diceSex: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceSex)
#else
        .init()
#endif
    }

    /// The "dice_standing" asset catalog image.
    static var diceStanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diceStanding)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "dice_anal" asset catalog image.
    static var diceAnal: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceAnal)
#else
        .init()
#endif
    }

    /// The "dice_back" asset catalog image.
    static var diceBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceBack)
#else
        .init()
#endif
    }

    /// The "dice_cowgirl" asset catalog image.
    static var diceCowgirl: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceCowgirl)
#else
        .init()
#endif
    }

    /// The "dice_dog" asset catalog image.
    static var diceDog: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceDog)
#else
        .init()
#endif
    }

    /// The "dice_doggy" asset catalog image.
    static var diceDoggy: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceDoggy)
#else
        .init()
#endif
    }

    /// The "dice_front" asset catalog image.
    static var diceFront: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceFront)
#else
        .init()
#endif
    }

    /// The "dice_licking" asset catalog image.
    static var diceLicking: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceLicking)
#else
        .init()
#endif
    }

    /// The "dice_oral" asset catalog image.
    static var diceOral: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceOral)
#else
        .init()
#endif
    }

    /// The "dice_sex" asset catalog image.
    static var diceSex: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceSex)
#else
        .init()
#endif
    }

    /// The "dice_standing" asset catalog image.
    static var diceStanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diceStanding)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

