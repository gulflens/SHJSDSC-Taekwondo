import SwiftUI
import MapKit

/// Full-screen picker that lets the user choose a branch location by:
/// 1. searching by name/address (MKLocalSearch, biased to UAE),
/// 2. tapping anywhere on the map to drop the pin,
/// 3. confirming with "Use this location".
///
/// Designed to be presented as a sheet from any branch edit form.
public struct BranchLocationPicker: View {
    @Environment(\.dismiss) private var dismiss

    private let initialCoordinate: CLLocationCoordinate2D
    private let onPick: (Double, Double) -> Void

    @State private var coordinate: CLLocationCoordinate2D
    @State private var camera: MapCameraPosition
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false

    public init(latitude: Double, longitude: Double, onPick: @escaping (Double, Double) -> Void) {
        // Default to central Sharjah when no coordinates have been set yet.
        let lat = (latitude == 0) ? 25.3463 : latitude
        let lon = (longitude == 0) ? 55.4209 : longitude
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.initialCoordinate = coord
        self.onPick = onPick
        _coordinate = State(initialValue: coord)
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                if !results.isEmpty {
                    resultsList
                    Divider()
                }
                mapBody
                coordinateBar
            }
            .background(Color.appBackground)
            .navigationTitle(Text("branch.pick_location"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                    .bareToolbarButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onPick(coordinate.latitude, coordinate.longitude)
                        dismiss()
                    } label: {
                        Text("branch.use_this_location").bold()
                    }
                    .bareToolbarButton()
                }
            }
        }
    }

    // MARK: - Pieces

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("branch.search_address", text: $query)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }
            if searching {
                ProgressView().controlSize(.small)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.cardBackground)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(results.prefix(8).enumerated()), id: \.offset) { _, item in
                    resultRow(item)
                    Divider()
                }
            }
        }
        .frame(maxHeight: 220)
        .background(Color.appBackground)
    }

    private func resultRow(_ item: MKMapItem) -> some View {
        Button {
            let coord = item.placemark.coordinate
            coordinate = coord
            camera = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            results = []
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: item.name ?? "—").scaledFont(.callout)
                    if let title = item.placemark.title, title != item.name {
                        Text(verbatim: title)
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var mapBody: some View {
        MapReader { proxy in
            Map(position: $camera) {
                Marker("", coordinate: coordinate)
                    .tint(Color.accentColor)
            }
            .mapStyle(.standard(elevation: .realistic))
            .onTapGesture { point in
                if let coord = proxy.convert(point, from: .local) {
                    coordinate = coord
                }
            }
        }
    }

    private var coordinateBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill").foregroundStyle(.secondary)
            Text(verbatim: String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude))
                .scaledFont(.caption, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
            Spacer()
            Text("branch.tap_to_move")
                .scaledFont(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color.cardBackground)
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; return }
        searching = true
        defer { searching = false }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        // Bias the search to the UAE so "Al Rahmania" doesn't return Riyadh.
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.3, longitude: 55.5),
            span: MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5)
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems
        } catch {
            print("BranchLocationPicker.search:", error)
            results = []
        }
    }

}

// MARK: - Inline preview row used inside branch edit forms

/// Compact row that shows a small map preview + current coordinates and a
/// button to open `BranchLocationPicker`. Drop this into any form section.
public struct BranchLocationField: View {
    @Binding public var latitude: Double
    @Binding public var longitude: Double
    @State private var showingPicker = false

    public init(latitude: Binding<Double>, longitude: Binding<Double>) {
        self._latitude = latitude
        self._longitude = longitude
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            preview
            Button {
                showingPicker = true
            } label: {
                Label(hasCoordinate ? "branch.change_location" : "branch.choose_on_map",
                      systemImage: "mappin.and.ellipse")
                    .scaledFont(.callout, weight: .bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            if hasCoordinate {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill").scaledFont(.caption2).foregroundStyle(.secondary)
                    Text(verbatim: String(format: "%.6f, %.6f", latitude, longitude))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            BranchLocationPicker(latitude: latitude, longitude: longitude) { lat, lon in
                latitude = lat
                longitude = lon
            }
        }
    }

    private var hasCoordinate: Bool { latitude != 0 || longitude != 0 }

    @ViewBuilder
    private var preview: some View {
        if hasCoordinate {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker("", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    .tint(Color.accentColor)
            }
            .id("\(latitude)-\(longitude)")
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .allowsHitTesting(false)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cardBackground)
                VStack(spacing: 6) {
                    Image(systemName: "mappin.slash")
                        .scaledFont(.title2)
                        .foregroundStyle(.secondary)
                    Text("branch.no_location_set")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
        }
    }
}
