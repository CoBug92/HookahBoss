import Foundation
@MainActor
final class PersonalMixStore: ObservableObject {
    @Published private(set) var mixes: [PersonalMixRecord]
    private let defaults: UserDefaults
    private let key: String?
    private let outboxKey:String?
    private var client: APIClient?
    @Published var syncError: String?

    init(defaults: UserDefaults = .standard, accountId: UUID? = nil) {
        self.defaults = defaults
        AccountCache.discardLegacy(defaults:defaults);key=accountId.map { AccountCache.key("personal.mixes.v1",accountId:$0) };outboxKey=accountId.map{AccountCache.key("personal.outbox.v1",accountId:$0)}
        mixes = key.flatMap { defaults.data(forKey:$0) }.flatMap { try? JSONDecoder().decode([PersonalMixRecord].self, from: $0) } ?? []
    }

    func add(_ mix: PersonalMixRecord) {
        mixes.insert(mix, at: 0)
        if let key,let data = try? JSONEncoder().encode(mixes) { defaults.set(data, forKey: key) }
    }
    func configure(client:APIClient?) async {
        self.client=client;guard let client else{return};await replayOutbox(client);guard let summaries=try? await client.personalMixes() else{return}
        var reconciled:[PersonalMixRecord]=[]
        for summary in summaries {
            guard let detail=try? await client.personalMix(id:summary.id) else{continue}
            let components=detail.components.map{ dto -> PersonalMixComponentRecord in
                let source:ComponentSource=dto.privateProductId != nil ? .personal : (dto.productId != nil ? .catalog:.personal)
                let sourceID=dto.privateProductId.map{"private:\($0.uuidString)"} ?? dto.productId?.uuidString ?? UUID().uuidString
                return .init(id:dto.id ?? UUID(),source:source,sourceID:sourceID,brand:dto.brandName,line:dto.lineName,flavor:dto.flavorName ?? dto.freeformName ?? "—",percentage:dto.percentage,flavorProfiles:dto.flavorProfiles)
            }
            reconciled.append(.init(id:summary.id,title:summary.title,components:components,createdAt:ISO8601DateFormatter().date(from:summary.createdAt) ?? Date(),isApproximate:detail.isApproximate ?? summary.isApproximate ?? false))
        }
        mixes=PersonalMixReconciler.merge(server:reconciled,cached:mixes,pending:pendingMixes());persist()
    }
    func addSynced(_ mix:PersonalMixRecord) async -> Bool {
        mixes.insert(mix,at:0);persist();guard let client else{return true}
        let input=PersonalMixWrite(clientId:mix.id,title:mix.title,score:nil,comment:nil,isApproximate:mix.isApproximate == true,components:mix.components.map{ component in
            let isPrivate=component.sourceID.hasPrefix("private:")
            let raw=isPrivate ? String(component.sourceID.dropFirst(8)):component.sourceID
            let uuid=UUID(uuidString:raw)
            return PersonalMixComponentWrite(productId:uuid != nil && !isPrivate ? uuid:nil,privateProductId:isPrivate ? uuid:nil,freeformName:uuid == nil ? component.flavor:nil,percentage:component.percentage)
        })
        do { let remote=try await client.createPersonalMix(input);if let index=mixes.firstIndex(where:{$0.id==mix.id}) { mixes[index]=PersonalMixRecord(id:remote.id,title:mix.title,components:mix.components,createdAt:mix.createdAt,isApproximate:mix.isApproximate);persist() };return true }
        catch {if error.isRetryableSyncFailure{enqueue(mix);persist();syncError=L10n.Content.Error.network;return true};mixes.removeAll{$0.id==mix.id};persist();syncError=L10n.Content.Error.network;return false}
    }
    private func persist(){if let key,let data=try? JSONEncoder().encode(mixes){defaults.set(data,forKey:key)}}
    private func enqueue(_ mix:PersonalMixRecord){guard let outboxKey else{return};let queue=(defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([PersonalMixRecord].self,from:$0)}) ?? [];defaults.set(try? JSONEncoder().encode(OutboxQueue.upserting(mix,in:queue){$0.id==$1.id}),forKey:outboxKey)}
    private func pendingMixes()->[PersonalMixRecord]{guard let outboxKey else{return []};return defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([PersonalMixRecord].self,from:$0)} ?? []}
    private func replayOutbox(_ client:APIClient) async {guard let outboxKey,var queue=defaults.data(forKey:outboxKey).flatMap({try? JSONDecoder().decode([PersonalMixRecord].self,from:$0)}) else{return};for mix in queue {let input=writeInput(mix);do{_ = try await client.createPersonalMix(input);queue.removeAll{$0.id==mix.id}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.id==mix.id};mixes.removeAll{$0.id==mix.id}}}};defaults.set(try? JSONEncoder().encode(queue),forKey:outboxKey);persist()}
    private func writeInput(_ mix:PersonalMixRecord)->PersonalMixWrite { PersonalMixWrite(clientId:mix.id,title:mix.title,score:nil,comment:nil,isApproximate:mix.isApproximate == true,components:mix.components.map{component in let isPrivate=component.sourceID.hasPrefix("private:");let raw=isPrivate ? String(component.sourceID.dropFirst(8)):component.sourceID;let uuid=UUID(uuidString:raw);return PersonalMixComponentWrite(productId:uuid != nil && !isPrivate ? uuid:nil,privateProductId:isPrivate ? uuid:nil,freeformName:uuid == nil ? component.flavor:nil,percentage:component.percentage)}) }
}
