import SwiftUI
#if os(iOS)
import UIKit

/// Modal sheet that lets the user reposition and zoom a freshly picked photo
/// inside a circular crop window. Confirmation renders the visible circle to
/// a square JPEG suitable for upload via the repository's avatar storage.
public struct RepositionPhotoSheet: View {
    public let image: UIImage
    public let onCancel: () -> Void
    public let onConfirm: (Data) -> Void

    @State private var offset: CGSize = .zero
    @State private var dragAnchor: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var pinchAnchor: CGFloat = 1.0
    @State private var processing = false

    private let cropDiameter: CGFloat = 300
    private let outputResolution: CGFloat = 1024
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    public init(
        image: UIImage,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (Data) -> Void
    ) {
        self.image = image
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 8)
                cropper
                Text("photo.reposition.hint")
                    .scaledFont(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                resetButton
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(Text("photo.reposition.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { onCancel() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        confirm()
                    } label: {
                        if processing {
                            ProgressView().tint(.white)
                        } else {
                            Text("photo.reposition.use").bold()
                        }
                    }
                    .foregroundStyle(.white)
                    .disabled(processing)
                }
            }
        }
    }

    private var cropper: some View {
        ZStack {
            transformedImage
        }
        .frame(width: cropDiameter, height: cropDiameter)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white.opacity(0.7), lineWidth: 2)
        )
        .contentShape(Circle())
        .gesture(dragGesture)
        .simultaneousGesture(magnifyGesture)
    }

    private var transformedImage: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: cropDiameter, height: cropDiameter)
            .scaleEffect(scale)
            .offset(offset)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: dragAnchor.width + value.translation.width,
                    height: dragAnchor.height + value.translation.height
                )
            }
            .onEnded { _ in
                dragAnchor = offset
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let next = pinchAnchor * value
                scale = min(maxScale, max(minScale, next))
            }
            .onEnded { _ in
                pinchAnchor = scale
            }
    }

    private var resetButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                offset = .zero
                dragAnchor = .zero
                scale = 1.0
                pinchAnchor = 1.0
            }
        } label: {
            Label("photo.reposition.reset", systemImage: "arrow.counterclockwise")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func confirm() {
        processing = true
        let snapshot = ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: cropDiameter, height: cropDiameter)
                .scaleEffect(scale)
                .offset(offset)
        }
        .frame(width: cropDiameter, height: cropDiameter)
        .clipShape(Circle())

        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = outputResolution / cropDiameter

        guard let rendered = renderer.uiImage,
              let data = rendered.jpegData(compressionQuality: 0.85) else {
            processing = false
            return
        }
        onConfirm(data)
    }
}
#endif
