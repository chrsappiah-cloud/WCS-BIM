import CoreLocation
import MapKit
import PhotosUI
import SwiftData
import SwiftUI

struct SiteCaptureSection: View {
    @Bindable var project: Project
    @Bindable var viewModel: ProjectDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var siteContextService = SiteContextService()
    @State private var ocrService = SiteNoteOCRService()
    @State private var newLandmarkTitle = ""
    @State private var observationTitle = "Site photo"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showRoomPlan = false
    @State private var showCamera = false
    @State private var fieldHub = APIIntegrationHub()

    var body: some View {
        VStack(spacing: 0) {
            LandmarkMapView(
                landmarks: project.landmarks,
                siteCoordinate: CLLocationCoordinate2D(
                    latitude: project.siteLatitude,
                    longitude: project.siteLongitude
                ),
                userLocation: locationService.currentLocation,
                identifiedPropertyCoordinate: nil,
                cameraPosition: $viewModel.mapCameraPosition
            )
            .frame(height: 260)

            Form {
                Section("Quick capture") {
                    cameraCaptureButton
                    Text("Capture a field photo before adding detailed site context.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SiteLocationPickerView(
                    project: project,
                    locationService: locationService,
                    onLocationApplied: { viewModel.configureMap(for: project) }
                )

                SiteContextFields(project: project)

                Section("Landmarks") {
                    TextField("Landmark title", text: $newLandmarkTitle)
                    Button("Add at site pin", systemImage: "mappin.and.ellipse") {
                        guard !newLandmarkTitle.isEmpty else { return }
                        viewModel.addLandmark(
                            at: CLLocationCoordinate2D(
                                latitude: project.siteLatitude,
                                longitude: project.siteLongitude
                            ),
                            title: newLandmarkTitle,
                            to: project,
                            context: modelContext
                        )
                        newLandmarkTitle = ""
                    }
                    ForEach(project.landmarks, id: \.id) { landmark in
                        VStack(alignment: .leading) {
                            Text(landmark.title).font(.headline)
                            Text(landmark.category).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(project.landmarks[i]) }
                    }
                }

                Section("Photos & observations") {
                    TextField("Observation title", text: $observationTitle)
                    cameraCaptureButton
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Import from library", systemImage: "photo.on.rectangle")
                    }
                    .accessibilityIdentifier("site.capture.photosPicker")
                    .onChange(of: selectedPhoto) { _, item in
                        Task { await importPhoto(from: item) }
                    }

                    ForEach(project.observations, id: \.id) { obs in
                        SiteObservationRow(observation: obs)
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(project.observations[i]) }
                    }
                }

                Section("Interior scan") {
                    Button("RoomPlan scan", systemImage: "view.3d") {
                        showRoomPlan = true
                    }
                }
            }
        }
        .navigationTitle("Full Site Capture")
        .accessibilityIdentifier("site.capture.form")
        .onAppear {
            locationService.requestPermission()
            locationService.startUpdates()
            siteContextService.syncProjectFields(from: project)
            fieldHub.activateFieldSensors()
        }
        .sheet(isPresented: $showCamera) {
            AppleCameraCaptureView(
                onImage: { image in
                    showCamera = false
                    Task { await importCapturedImage(image) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showRoomPlan) {
            NavigationStack {
                RoomPlanCapturePlaceholder()
                    .navigationTitle("RoomPlan")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showRoomPlan = false }
                        }
                    }
            }
        }
    }

    private var cameraCaptureButton: some View {
        PrimaryButton(
            "Live camera (AVFoundation)",
            layout: .compact,
            accessibilityIdentifier: "site.capture.camera"
        ) {
            fieldHub.activateFieldSensors()
            showCamera = true
        }
    }

    private func importPhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await importCapturedImage(image)
        selectedPhoto = nil
    }

    private func importCapturedImage(_ image: UIImage) async {
        let obsID = UUID()
        let media = await fieldHub.processCapturedImage(image, projectID: project.id, observationID: obsID)
        let observation = SiteObservation(
            title: observationTitle.isEmpty ? "Site photo" : observationTitle,
            note: media.ocrText.isEmpty ? "Photo captured on site." : media.ocrText,
            latitude: media.latitude,
            longitude: media.longitude,
            photoPath: media.savedPath
        )
        observation.id = obsID
        project.observations.append(observation)
        modelContext.insert(observation)
        observationTitle = "Site photo"
    }
}

private struct SiteObservationRow: View {
    let observation: SiteObservation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let path = observation.photoPath, let image = SitePhotoStore.load(path: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(observation.title).font(.headline)
                if !observation.note.isEmpty {
                    Text(observation.note).font(.caption).lineLimit(3)
                }
                Text(observation.capturedAt, style: .relative).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
