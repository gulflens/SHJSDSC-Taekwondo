import SwiftUI

/// Renders a Menu with one ShareLink per `ExportFormat`. Files are written to
/// the temporary directory at button-tap time so we don't generate them on
/// every render.
public struct ExportButton: View {
    public let baseFilename: String
    public let csvProvider: () -> Data
    public let pdfProvider: () -> Data

    public init(
        baseFilename: String,
        csvProvider: @escaping () -> Data,
        pdfProvider: @escaping () -> Data = { Data() }
    ) {
        self.baseFilename = baseFilename
        self.csvProvider = csvProvider
        self.pdfProvider = pdfProvider
    }

    public var body: some View {
        Menu {
            shareLink(format: .csv)
            let pdfData = pdfProvider()
            if !pdfData.isEmpty {
                shareLink(format: .pdf, prebuilt: pdfData)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .accessibilityLabel(Text("export.share"))
        }
    }

    @ViewBuilder
    private func shareLink(format: ExportFormat, prebuilt: Data? = nil) -> some View {
        if let url = writeToTemp(format: format, data: prebuilt ?? csvProvider()) {
            ShareLink(item: url) {
                Label(LocalizedStringKey(format.labelKey), systemImage: format == .csv ? "doc.text" : "doc.richtext")
            }
        }
    }

    private func writeToTemp(format: ExportFormat, data: Data) -> URL? {
        guard !data.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(baseFilename).\(format.fileExtension)")
        try? data.write(to: url)
        return url
    }
}
