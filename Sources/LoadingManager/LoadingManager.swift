//  Created by Axel Ancona Esselmann on 9/20/23.
//

import Foundation
import SwiftUI

public enum LoadingScope {
    case local(UUID)
    case global
}

@MainActor
public class LoadingManager: ObservableObject {

    private var activeLocalScopes: Set<UUID> = []
    private var activeGlobalLoadingKeys: Set<UUID> = []
    private var localLoadigKeys: [UUID: Set<UUID>] = [:]

    public init() {
        
    }

    @MainActor
    public func isLoading(forScope scope: LoadingScope) -> Bool {
        switch scope {
        case .local(let localScope):
            for localLoadingScopes in localLoadigKeys.values {
                if localLoadingScopes.contains(localScope) {
                    return true
                }
            }
            return false
        case .global:
            return !activeGlobalLoadingKeys.isEmpty
        }
    }

    @MainActor
    public func isLoading(forLocalScopeId id: UUID) -> Bool {
        self.isLoading(forScope: .local(id))
    }

    @MainActor
    public var isLoadingGlobally: Bool {
        self.isLoading(forScope: .global)
    }

    @MainActor
    public var isLoading: Bool {
        guard activeGlobalLoadingKeys.isEmpty else {
            return true
        }
        guard localLoadigKeys.isEmpty else {
            return true
        }
        return false
    }

    @MainActor
    public func setLoading(key: UUID, scope: LoadingScope) {
        switch scope {
        case .global:
            activeGlobalLoadingKeys.insert(key)
        case .local(let localScope):
            var localScopes = localLoadigKeys[key] ?? []
            localScopes.insert(localScope)
            localLoadigKeys[key] = localScopes
        }
        self.objectWillChange.send()
    }

    @MainActor
    public func setLoading(key: UUID) {
        self.setLoading(key: key, scope: .global)
    }

    @MainActor
    public func setLoading(key: UUID, localScopeId: UUID) {
        self.setLoading(key: key, scope: .local(localScopeId))
    }

    @MainActor
    public func loadingComplete(key: UUID) {
        if activeGlobalLoadingKeys.contains(key) {
            activeGlobalLoadingKeys.remove(key)
        } else {
            localLoadigKeys[key] = nil
        }
        self.objectWillChange.send()
    }

    @MainActor
    public func set(isLoading: Bool, for key: UUID) {
        if isLoading {
            setLoading(key: key)
        } else {
            loadingComplete(key: key)
        }
    }

    @MainActor
    public func enterScope(_ scope: LoadingScope) {
        guard case .local(let uuid) = scope else {
            return
        }
        activeLocalScopes.insert(uuid)
    }

    @MainActor
    public func exitScope(_ scope: LoadingScope) {
        guard case .local(let uuid) = scope else {
            return
        }
        activeLocalScopes.remove(uuid)
    }

    @MainActor
    public func enterLocalScope(withId id: UUID) {
        self.enterScope(.local(id))
    }

    @MainActor
    public func exitLocalScope(withId id: UUID) {
        self.exitScope(.local(id))
    }
}

