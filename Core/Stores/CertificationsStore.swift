import Foundation
import Observation

@Observable @MainActor
public final class CertificationsStore {
    public private(set) var certifications: [Certification] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            certifications = try await repository.certifications()
        } catch {
            print("CertificationsStore.loadAll:", error)
        }
    }

    public func load(coachID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            certifications = try await repository.certifications(coachID: coachID)
        } catch {
            print("CertificationsStore.load:", error)
        }
    }

    public var expired: [Certification] {
        certifications.filter { $0.severity == .expired }
    }

    public var expiringSoon: [Certification] {
        certifications.filter { $0.severity == .expiring }
    }

    public func renew(_ cert: Certification, newExpiry: Date) async {
        var updated = cert
        updated.issuedAt = Date()
        updated.expiresAt = newExpiry
        do {
            try await repository.upsert(certification: updated)
            await loadAll()
        } catch {
            print("CertificationsStore.renew:", error)
        }
    }
}
