import SwiftUI

public struct LaunchView: View {
    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            Image(isPortrait ? "LaunchLogoPortrait" : "LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
