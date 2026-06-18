import Foundation
import OSLog

enum BIMAPIError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: "The BIM API base URL is invalid."
        case .invalidResponse: "The BIM API returned an invalid response."
        case let .server(status, message): "BIM API error \(status): \(message)"
        }
    }
}

actor BIMAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let bearerToken: String?
    private let logger = Logger(subsystem: "wcs.WCS-BIM", category: "BIMAPI")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURL: URL, bearerToken: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.session = session
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    static func configured() throws -> BIMAPIClient {
        let raw = UserDefaults.standard.string(forKey: "bimAPIBaseURL") ?? "http://127.0.0.1:3000"
        guard let url = URL(string: raw) else { throw BIMAPIError.invalidBaseURL }
        return BIMAPIClient(
            baseURL: url,
            bearerToken: UserDefaults.standard.string(forKey: "bimAPIBearerToken")
        )
    }

    func userAccess() async throws -> APIUserAccess {
        try await request(path: "/api/session/permissions")
    }

    func dashboard() async throws -> APIDashboard {
        try await request(path: "/api/dashboard")
    }

    func projects() async throws -> [APIProject] {
        try await request(path: "/projects")
    }

    func project(id: String) async throws -> APIProject {
        try await request(path: "/api/projects/\(id)")
    }

    func materials(projectID: String) async throws -> [APIMaterial] {
        try await request(path: "/api/projects/\(projectID)/materials")
    }

    func createMaterial(_ payload: APIMaterialCreateRequest) async throws -> APIMaterial {
        try await request(path: "/api/materials", method: "POST", body: payload)
    }

    func tests(projectID: String) async throws -> [APIMaterialTest] {
        try await request(path: "/api/projects/\(projectID)/tests")
    }

    func bimElements(projectID: String) async throws -> [APIBIMElement] {
        try await request(path: "/api/projects/\(projectID)/bim-elements")
    }

    func designAlternatives(projectID: String) async throws -> [APIDesignAlternative] {
        try await request(path: "/projects/\(projectID)/design-alternatives")
    }

    func fabricationModules(projectID: String) async throws -> [APIFabricationModule] {
        try await request(path: "/projects/\(projectID)/fabrication-modules")
    }

    func optimizeMix(_ payload: APIMixOptimizerRequest) async throws -> APIMixOptimizerResult {
        try await request(path: "/ai/mix-optimizer", method: "POST", body: payload)
    }

    func predictMaterialProperty(_ payload: APIMaterialPredictionRequest) async throws -> APIMaterialPredictionResult {
        try await request(path: "/ai/material-predict", method: "POST", body: payload)
    }

    func predictMaterials(_ payload: APIMaterialsPredictionRequest) async throws -> APIMaterialsPredictionResult {
        try await request(path: "/ai/materials/predict", method: "POST", body: payload)
    }

    func optimizeMaterials(_ payload: APIMixOptimizerRequest) async throws -> APIMixOptimizerResult {
        try await request(path: "/ai/materials/optimize", method: "POST", body: payload)
    }

    func screenInspectionImage(_ payload: APIImageQCRequest) async throws -> APIImageQCResult {
        try await request(path: "/ai/defect-qc", method: "POST", body: payload)
    }

    func generateQCReport(_ payload: APIQCReportRequest) async throws -> APIQCReportResult {
        try await request(path: "/ai/qc-report", method: "POST", body: payload)
    }

    func linkBIM(projectID: String, payload: APIBIMLinkRequest) async throws -> APIBIMLinkResult {
        try await request(path: "/api/projects/\(projectID)/bim-link", method: "POST", body: payload)
    }

    func generateMaterialTestReport(_ payload: APIMaterialTestReportRequest) async throws -> APIMaterialTestReportResult {
        try await request(path: "/api/reports/material-test", method: "POST", body: payload)
    }

    func models() async throws -> [APIModelRecord] {
        try await request(path: "/api/models")
    }

    func createModel(_ payload: APIModelCreateRequest) async throws -> APIModelRecord {
        try await request(path: "/api/models", method: "POST", body: payload)
    }

    func activateModel(id: String) async throws -> APIModelRecord {
        try await request(path: "/api/models/\(id)/activate", method: "POST", bodyData: Data("{}".utf8))
    }

    func retrainingStatus() async throws -> APIRetrainStatus {
        try await request(path: "/api/retrain/status")
    }

    func runRetraining() async throws -> APIRetrainRunResult {
        try await request(path: "/api/retrain/run", method: "POST", bodyData: Data("{}".utf8))
    }

    func uploadFile(
        data: Data,
        filename: String,
        contentType: String,
        projectID: String,
        bucket: String = "project-files"
    ) async throws -> APIUploadResult {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.appendMultipartField(name: "projectId", value: projectID, boundary: boundary)
        body.appendMultipartField(name: "bucket", value: bucket, boundary: boundary)
        body.appendMultipartFile(name: "file", filename: filename, contentType: contentType, data: data, boundary: boundary)
        body.append(Data("--\(boundary)--\r\n".utf8))

        return try await request(
            path: "/api/uploads/file",
            method: "POST",
            bodyData: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    func signedURL(
        projectID: String,
        bucket: String,
        path: String,
        expiresIn: Int = 3_600
    ) async throws -> APISignedURLResult {
        try await request(
            path: "/api/uploads/signed-url",
            method: "POST",
            body: APISignedURLRequest(
                projectId: projectID,
                bucket: bucket,
                path: path,
                expiresIn: expiresIn
            )
        )
    }

    private func request<Response: Decodable>(
        path: String,
        method: String = "GET"
    ) async throws -> Response {
        try await request(path: path, method: method, bodyData: nil)
    }

    private func request<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body
    ) async throws -> Response {
        try await request(path: path, method: method, bodyData: try encoder.encode(body))
    }

    private func request<Response: Decodable>(
        path: String,
        method: String,
        bodyData: Data?,
        contentType: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        if let bodyData {
            request.httpBody = bodyData
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }

        logger.info("\(method, privacy: .public) \(path, privacy: .public)")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BIMAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw BIMAPIError.server(
                status: http.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Unknown server error"
            )
        }
        return try decoder.decode(Response.self, from: data)
    }
}

private extension Data {
    nonisolated mutating func appendMultipartField(name: String, value: String, boundary: String) {
        append(Data("--\(boundary)\r\n".utf8))
        append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
        append(Data("\(value)\r\n".utf8))
    }

    nonisolated mutating func appendMultipartFile(
        name: String,
        filename: String,
        contentType: String,
        data: Data,
        boundary: String
    ) {
        append(Data("--\(boundary)\r\n".utf8))
        append(Data("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".utf8))
        append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
        append(data)
        append(Data("\r\n".utf8))
    }
}
