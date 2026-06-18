import CoreLocation
import MapKit
import SwiftUI

struct SiteLocationPickerView: View {
    @Bindable var project: Project
    var locationService: LocationService
    var onLocationApplied: (() -> Void)?

    @State private var inputMode: InputMode = .liveGPS
    @State private var searchQuery = ""
    @State private var manualAddress = ""
    @State private var manualLatitude = 0.0
    @State private var manualLongitude = 0.0
    @State private var autoValuationOnGPS = true
    @State private var searchService = LocationSearchService()
    @State private var locatorService = PropertyLocatorService()
    @State private var valuationResult: SiteValuationResult?
    @State private var isValuating = false
    @State private var statusMessage: String?
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    private let valuationService = SiteValuationService()

    enum InputMode: String, CaseIterable, Identifiable {
        case liveGPS = "Live"
        case search = "Search"
        case manual = "Manual"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .liveGPS: "location.fill.viewfinder"
            case .search: "magnifyingglass"
            case .manual: "mappin.and.ellipse"
            }
        }
    }

    var body: some View {
        Group {
            if inputMode == .liveGPS {
                Section {
                    LiveLocatorMapView(
                        userLocation: locationService.currentLocation,
                        siteCoordinate: savedCoordinate,
                        identifiedProperty: locatorService.primaryProperty,
                        cameraPosition: $mapCameraPosition,
                        isScanning: locatorService.isScanning
                    )
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }

            Section {
                locatorStatusHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))

            Section {
                Picker("Input mode", selection: $inputMode) {
                    ForEach(InputMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("site.location.modePicker")
                .onChange(of: inputMode) { _, mode in
                    handleModeChange(mode)
                }

                switch inputMode {
                case .search:
                    searchFields
                case .manual:
                    manualFields
                case .liveGPS:
                    liveGPSFields
                }
            } header: {
                Text("Locate property")
            }

            if inputMode == .liveGPS, !locatorService.nearbyProperties.isEmpty {
                Section("Nearby properties") {
                    ForEach(locatorService.nearbyProperties) { property in
                        propertyCandidateRow(property)
                    }
                }
            }

            Section {
                valuationHeroCard
            } header: {
                Text("Valuation")
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(WCSFont.caption())
                        .foregroundStyle(WCSColor.neutralText.opacity(0.72))
                        .accessibilityIdentifier("site.location.status")
                }
            }
        }
        .onAppear {
            syncManualFieldsFromProject()
            refreshValuationDisplay()
            configureMapCamera()
            if inputMode == .liveGPS {
                activateLiveLocator()
            }
        }
        .onDisappear {
            locatorService.stopLiveTracking()
            locationService.enableStandardMode()
        }
        .onChange(of: locationService.currentLocation) { _, location in
            guard inputMode == .liveGPS, let location else { return }
            mapCameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
            ))
            Task {
                await locatorService.handleLocationUpdate(location)
                if autoValuationOnGPS, let property = locatorService.primaryProperty {
                    await applyIdentifiedProperty(property, source: "Live property lock")
                }
            }
        }
    }

    // MARK: - Header

    private var locatorStatusHeader: some View {
        CardView(
            title: inputMode == .liveGPS ? "Real-time property locator" : "Property identification",
            subtitle: locatorService.statusText,
            systemImage: inputMode == .liveGPS ? "location.fill.viewfinder" : "building.2",
            chips: locatorStatusChips
        ) {
            if inputMode == .liveGPS {
                HStack(spacing: WCSSpacing.sm) {
                    gpsSignalIndicator
                    if let location = locationService.currentLocation {
                        Text("±\(Int(max(location.horizontalAccuracy, 1))) m")
                            .font(WCSFont.caption(11))
                            .foregroundStyle(WCSColor.neutralText.opacity(0.7))
                    }
                    Spacer()
                    if locatorService.isLiveTracking {
                        StatusChip(text: "Live", tone: .inProgress)
                    }
                }
            }
        }
        .accessibilityIdentifier("site.location.locatorHeader")
    }

    private var gpsSignalIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(locationService.currentLocation == nil ? WCSColor.neutral4 : WCSColor.success)
                .frame(width: 8, height: 8)
                .overlay {
                    if locationService.currentLocation != nil && inputMode == .liveGPS {
                        Circle()
                            .stroke(WCSColor.success.opacity(0.45), lineWidth: 2)
                            .scaleEffect(locatorService.isScanning ? 1.8 : 1.2)
                            .opacity(locatorService.isScanning ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: locatorService.isScanning
                            )
                    }
                }
            Text(locationService.currentLocation == nil ? "No GPS" : "GPS active")
                .font(WCSFont.caption(11))
                .foregroundStyle(WCSColor.neutralText.opacity(0.75))
        }
        .accessibilityIdentifier("site.location.gpsIndicator")
    }

    private var locatorStatusChips: [String] {
        var chips: [String] = []
        if let property = locatorService.primaryProperty {
            chips.append(property.category)
            if property.distanceMetres > 0 {
                chips.append("\(Int(property.distanceMetres)) m away")
            }
        } else if project.siteAddress.isEmpty {
            chips.append("Awaiting fix")
        } else {
            chips.append("Saved site")
        }
        return chips
    }

    // MARK: - Mode fields

    @ViewBuilder
    private var searchFields: some View {
        HStack(spacing: WCSSpacing.sm) {
            TextField("Search address or place", text: $searchQuery)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("site.location.searchField")

            Button {
                Task {
                    await searchService.search(
                        query: searchQuery,
                        near: currentCoordinateIfSet
                    )
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(WCSColor.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(searchService.isSearching || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            .accessibilityIdentifier("site.location.searchButton")
        }

        if searchService.isSearching {
            HStack(spacing: 8) {
                ProgressView()
                Text("Searching MapKit…")
                    .font(WCSFont.caption())
                    .foregroundStyle(.secondary)
            }
        }

        if let error = searchService.lastError, !searchService.isSearching {
            Text(error).font(WCSFont.caption()).foregroundStyle(WCSColor.error)
        }

        ForEach(searchService.searchResults) { result in
            Button {
                Task { await applySearchResult(result) }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(WCSColor.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(WCSFont.body(15))
                            .fontWeight(.semibold)
                            .foregroundStyle(WCSColor.neutralText)
                        Text(result.subtitle)
                            .font(WCSFont.caption())
                            .foregroundStyle(WCSColor.neutralText.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WCSColor.neutral4)
                }
                .padding(.vertical, 4)
            }
            .accessibilityIdentifier("site.location.searchResult")
        }
    }

    @ViewBuilder
    private var manualFields: some View {
        TextField("Street address", text: $manualAddress, axis: .vertical)
            .textInputAutocapitalization(.words)
            .accessibilityIdentifier("site.location.manualAddress")

        HStack(spacing: WCSSpacing.sm) {
            TextField("Latitude", value: $manualLatitude, format: .number)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("site.location.manualLatitude")
            TextField("Longitude", value: $manualLongitude, format: .number)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("site.location.manualLongitude")
        }

        PrimaryButton("Apply manual location", layout: .fullWidth, accessibilityIdentifier: "site.location.manualApply") {
            Task { await applyManualLocation() }
        }
    }

    @ViewBuilder
    private var liveGPSFields: some View {
        Toggle("Auto-valuation when property is identified", isOn: $autoValuationOnGPS)
            .accessibilityIdentifier("site.location.autoValuationToggle")

        if let location = locationService.currentLocation {
            LabeledContent("Live coordinates") {
                Text(String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude))
                    .font(.caption.monospaced())
            }
            .accessibilityIdentifier("site.location.liveCoordinates")

            if let property = locatorService.primaryProperty {
                identifiedPropertyCard(property, isPrimary: true)
            }

            HStack(spacing: WCSSpacing.sm) {
                PrimaryButton("Lock property for valuation", layout: .compact, accessibilityIdentifier: "site.location.useLiveGPS") {
                    Task {
                        if let property = locatorService.primaryProperty {
                            await applyIdentifiedProperty(property, source: "Property locked from live locator")
                        } else {
                            await applyLiveLocation(location)
                        }
                    }
                }

                Button("Rescan") {
                    Task { await locatorService.scan(at: location, reason: "Manual rescan") }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("site.location.rescan")
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Waiting for GPS fix…")
                    .font(WCSFont.body(15))
                    .foregroundStyle(WCSColor.neutralText)
                Text("Move to an open area or enable location access to identify the property you are standing at.")
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.72))
            }
            .accessibilityIdentifier("site.location.waitingGPS")

            PrimaryButton("Enable location access", layout: .fullWidth, accessibilityIdentifier: "site.location.requestGPS") {
                activateLiveLocator()
            }
        }

        if let error = locationService.lastError {
            Text(error).font(WCSFont.caption()).foregroundStyle(WCSColor.error)
        }
    }

    // MARK: - Property & valuation cards

    @ViewBuilder
    private func propertyCandidateRow(_ property: IdentifiedProperty) -> some View {
        Button {
            locatorService.selectProperty(property)
            Task { await applyIdentifiedProperty(property, source: "Nearby property selected") }
        } label: {
            identifiedPropertyCard(property, isPrimary: property.id == locatorService.primaryProperty?.id)
        }
        .accessibilityIdentifier("site.location.nearbyProperty")
    }

    @ViewBuilder
    private func identifiedPropertyCard(_ property: IdentifiedProperty, isPrimary: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPrimary ? "building.2.fill" : "building.2")
                .font(.title2)
                .foregroundStyle(isPrimary ? WCSColor.secondary : WCSColor.primary)
                .frame(width: 40, height: 40)
                .background((isPrimary ? WCSColor.secondary : WCSColor.primary).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(property.name)
                    .font(WCSFont.body(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(WCSColor.neutralText)
                Text(property.address)
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.72))
                HStack(spacing: 6) {
                    StatusChip(text: property.category, tone: .neutral)
                    if property.distanceMetres > 0 {
                        StatusChip(text: "\(Int(property.distanceMetres)) m", tone: .inProgress)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(WCSSpacing.sm)
        .background(WCSColor.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                .stroke(isPrimary ? WCSColor.secondary.opacity(0.35) : WCSColor.separator.opacity(0.25), lineWidth: 1)
        )
        .accessibilityIdentifier("site.location.identifiedProperty")
    }

    @ViewBuilder
    private var valuationHeroCard: some View {
        VStack(alignment: .leading, spacing: WCSSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Indicative site value")
                        .font(WCSFont.caption())
                        .foregroundStyle(WCSColor.neutralText.opacity(0.72))
                    if let valuationResult {
                        Text(
                            valuationResult.estimatedValue,
                            format: .currency(code: valuationResult.currency).precision(.fractionLength(0))
                        )
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(WCSColor.primary)
                        .accessibilityIdentifier("site.location.valuationValue")
                    } else {
                        Text("—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(WCSColor.neutral4)
                    }
                }
                Spacer()
                if let valuationResult {
                    VStack(alignment: .trailing, spacing: 6) {
                        StatusChip(
                            text: valuationResult.confidence.formatted(.percent.precision(.fractionLength(0))),
                            tone: .resolved
                        )
                        if let name = valuationResult.propertyName {
                            Text(name)
                                .font(WCSFont.caption(11))
                                .foregroundStyle(WCSColor.neutralText.opacity(0.7))
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                        }
                    }
                }
            }

            if !project.siteAddress.isEmpty {
                Label(project.siteAddress, systemImage: "mappin.and.ellipse")
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.8))
                    .accessibilityIdentifier("site.location.savedAddress")
            }

            LabeledContent("Coordinates") {
                Text(String(format: "%.5f, %.5f", project.siteLatitude, project.siteLongitude))
                    .font(.caption.monospaced())
            }
            .accessibilityIdentifier("site.location.savedCoordinates")

            if let valuationResult {
                Text(valuationResult.basisDescription)
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.72))
                if let valuatedAt = project.valuatedAt {
                    Text("Updated \(valuatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(WCSFont.caption(11))
                        .foregroundStyle(WCSColor.neutralText.opacity(0.55))
                }
            }

            PrimaryButton(
                isValuating ? "Calculating…" : "Run site valuation",
                layout: .fullWidth,
                isEnabled: !isValuating && (project.siteLatitude != 0 || project.siteLongitude != 0),
                accessibilityIdentifier: "site.location.runValuation"
            ) {
                Task { await runValuation(using: locatorService.primaryProperty) }
            }
        }
        .wcsCard()
    }

    // MARK: - Helpers

    private var savedCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: project.siteLatitude, longitude: project.siteLongitude)
    }

    private var currentCoordinateIfSet: CLLocationCoordinate2D? {
        guard project.siteLatitude != 0 || project.siteLongitude != 0 else { return nil }
        return savedCoordinate
    }

    private func handleModeChange(_ mode: InputMode) {
        switch mode {
        case .liveGPS:
            activateLiveLocator()
        case .search, .manual:
            locatorService.stopLiveTracking()
            locationService.enableStandardMode()
        }
    }

    private func activateLiveLocator() {
        locationService.requestPermission()
        locationService.enableLiveLocatorMode()
        locationService.startUpdates()
        locatorService.startLiveTracking()
        if let location = locationService.currentLocation {
            Task {
                await locatorService.scan(at: location, reason: "Live locator started")
                mapCameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                ))
            }
        }
    }

    private func configureMapCamera() {
        if let location = locationService.currentLocation, inputMode == .liveGPS {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
            ))
        } else if project.siteLatitude != 0 || project.siteLongitude != 0 {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: savedCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    private func syncManualFieldsFromProject() {
        manualAddress = project.siteAddress
        manualLatitude = project.siteLatitude
        manualLongitude = project.siteLongitude
        searchQuery = project.siteAddress.isEmpty ? project.name : project.siteAddress
    }

    private func refreshValuationDisplay() {
        guard project.estimatedSiteValue > 0 else { return }
        valuationResult = valuationService.valuate(
            project: project,
            address: project.siteAddress.nilIfEmpty,
            identifiedProperty: locatorService.primaryProperty
        )
    }

    private func applySearchResult(_ result: LocationSearchResult) async {
        let property = IdentifiedProperty(
            name: result.title,
            address: result.fullAddress,
            coordinate: result.coordinate,
            category: "Search result",
            source: "search"
        )
        await applyIdentifiedProperty(property, source: "Search result applied.")
    }

    private func applyManualLocation() async {
        let property = IdentifiedProperty(
            name: manualAddress.isEmpty ? "Manual pin" : manualAddress,
            address: manualAddress,
            coordinate: CLLocationCoordinate2D(latitude: manualLatitude, longitude: manualLongitude),
            category: "Manual entry",
            source: "manual"
        )
        await applyIdentifiedProperty(property, source: "Manual location applied.")
    }

    private func applyLiveLocation(_ location: CLLocation) async {
        await locatorService.scan(at: location, reason: "Live GPS scan")
        if let property = locatorService.primaryProperty {
            await applyIdentifiedProperty(property, source: "Live GPS property identified.")
        } else {
            var address = project.siteAddress
            if address.isEmpty {
                address = await searchService.reverseGeocode(coordinate: location.coordinate) ?? ""
            }
            await applyLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                address: address,
                identifiedProperty: nil,
                source: "Live GPS coordinates applied."
            )
        }
    }

    private func applyIdentifiedProperty(_ property: IdentifiedProperty, source: String) async {
        await applyLocation(
            latitude: property.coordinate.latitude,
            longitude: property.coordinate.longitude,
            address: property.address,
            identifiedProperty: property,
            source: source
        )
    }

    private func applyLocation(
        latitude: Double,
        longitude: Double,
        address: String,
        identifiedProperty: IdentifiedProperty?,
        source: String
    ) async {
        project.siteLatitude = latitude
        project.siteLongitude = longitude
        if !address.isEmpty {
            project.siteAddress = address
            manualAddress = address
        }
        manualLatitude = latitude
        manualLongitude = longitude
        locationService.setMapCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        onLocationApplied?()
        statusMessage = source

        let shouldValuate = autoValuationOnGPS || inputMode != .liveGPS
        if shouldValuate {
            await runValuation(using: identifiedProperty ?? locatorService.primaryProperty)
        }
    }

    private func runValuation(using identifiedProperty: IdentifiedProperty? = nil) async {
        guard project.siteLatitude != 0 || project.siteLongitude != 0 else {
            statusMessage = "Set coordinates before running valuation."
            return
        }

        isValuating = true
        defer { isValuating = false }

        let resolvedProperty = identifiedProperty ?? locatorService.primaryProperty

        if project.siteAddress.isEmpty {
            if let resolved = await searchService.reverseGeocode(coordinate: savedCoordinate) {
                project.siteAddress = resolved
                manualAddress = resolved
            }
        }

        let result = valuationService.valuate(
            project: project,
            address: project.siteAddress.nilIfEmpty,
            identifiedProperty: resolvedProperty
        )
        valuationService.apply(result, to: project)
        valuationResult = result
        statusMessage = "Valuation updated for \(result.propertyName ?? result.locality)."
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
