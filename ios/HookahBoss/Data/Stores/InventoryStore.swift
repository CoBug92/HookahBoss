import SwiftUI

enum InventoryLevel: String, CaseIterable, Codable, Identifiable {
    case plenty, low, empty

    var id: String { rawValue }
    var title: String { switch self {case .plenty:L10n.Inventory.Level.plenty;case .low:L10n.Inventory.Level.low;case .empty:L10n.Inventory.Level.empty} }
    var color: Color {
        switch self {
        case .plenty: .green
        case .low: .orange
        case .empty: .secondary
        }
    }
}

struct InventoryItem: Identifiable, Codable, Hashable {
    let id: String
    let brand: String
    let line: String?
    let flavor: String
    var level: InventoryLevel
    var flavorProfiles: [String]? = nil

    var brandAndLine: String { [brand, line].compactMap { $0 }.joined(separator: " · ") }
}

@MainActor
final class InventoryStore: ObservableObject {
    @Published private(set) var items: [InventoryItem] { didSet { save() } }
    private let storageKey: String?
    private let outboxKey:String?
    private let privateOutboxKey:String?
    private var client: (any InventoryRemoteServing)?
    @Published var syncError: String?

    init(defaults: any KeyValueStoring, accountId: UUID? = nil) {
        storageKey=accountId.map { AccountCache.key("inventory.v1",accountId:$0) };outboxKey=accountId.map{AccountCache.key("inventory.outbox.v1",accountId:$0)};privateOutboxKey=accountId.map{AccountCache.key("private.outbox.v1",accountId:$0)}
        if let storageKey,let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            items = saved
        } else if accountId != nil {
            items = []
        } else { items=[] }
        self.defaults = defaults
    }

    func setLevel(_ level: InventoryLevel, for id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let old=items[index].level
        items[index].level = level
        guard let client else{return};let isPrivate=id.hasPrefix("private:"),raw=isPrivate ? String(id.dropFirst(8)):id;guard let productId=UUID(uuidString:raw)else{return}
        Task { do { _ = try await client.upsertInventory(.init(productId:isPrivate ? nil:productId,privateProductId:isPrivate ? productId:nil,level:level.rawValue)) } catch { if error.isRetryableSyncFailure { self.enqueue(.init(productId:isPrivate ? nil:productId,privateProductId:isPrivate ? productId:nil,level:level)) } else if let current=self.items.firstIndex(where:{$0.id==id}) { self.items[current].level=old };self.syncError=L10n.Content.Error.network } }
    }

    func bootstrap(from products: [TobaccoProductDTO]) {
        guard items.isEmpty else { return }
    }
    func configure(client:(any InventoryRemoteServing)?,products:[TobaccoProductDTO]) async {
        self.client=client;await replayPrivateOutbox();await replayOutbox()
        let productMap=Dictionary(uniqueKeysWithValues:products.map{($0.id,$0)});let saved=items
        items=saved.compactMap{item in guard let id=UUID(uuidString:item.id),let product=productMap[id] else{return item.id.hasPrefix("private:") ? item:nil};return InventoryItem(id:item.id,brand:product.brandName,line:product.lineName,flavor:product.name,level:item.level,flavorProfiles:product.tags.map(\.profile))}
        guard let remote=try? await client?.inventory() else{return}
        for dto in remote {guard let level=InventoryLevel(rawValue:dto.level)else{continue};let id=dto.productId?.uuidString ?? dto.privateProductId.map{"private:\($0.uuidString)"};guard let id else{continue};let profiles=items.first(where:{$0.id==id})?.flavorProfiles;let value=InventoryItem(id:id,brand:dto.brandName ?? "",line:dto.lineName,flavor:dto.flavorName ?? "",level:level,flavorProfiles:profiles);if let index=items.firstIndex(where:{$0.id==id}){items[index]=value}else{items.append(value)}}
        let pairs:[(UUID,InventoryLevel)]=remote.compactMap{dto in guard let id=dto.productId,let level=InventoryLevel(rawValue:dto.level)else{return nil};return(id,level)}
        let remoteLevels:[UUID:InventoryLevel]=Dictionary(uniqueKeysWithValues:pairs)
        let effective=InventoryProjection.overlay(levels:remoteLevels,pending:pendingMutations())
        for (id,level) in effective {if let index=items.firstIndex(where:{$0.id==id.uuidString}){items[index].level=level}}
    }
    func add(_ product:TobaccoProductDTO){guard !items.contains(where:{$0.id==product.id.uuidString})else{return};items.append(.init(id:product.id.uuidString,brand:product.brandName,line:product.lineName,flavor:product.name,level:.plenty,flavorProfiles:product.tags.map(\.profile)));setLevel(.plenty,for:product.id.uuidString)}
    func addPrivate(_ product:PrivateProductDTO){let id="private:\(product.id.uuidString)";guard !items.contains(where:{$0.id==id})else{return};items.append(.init(id:id,brand:product.brandName,line:product.lineName,flavor:product.flavorName,level:.plenty,flavorProfiles:product.flavorProfiles));setLevel(.plenty,for:id)}
    func createPrivate(brand:String,line:String?,flavor:String,profiles:[String])async->Bool{let id=UUID(),input=PrivateProductWrite(clientId:id,brandName:brand,lineName:line,flavorName:flavor,flavorProfiles:profiles);let local=PrivateProductDTO(id:id,brandName:brand,lineName:line,flavorName:flavor,flavorProfiles:profiles,createdAt:ISO8601DateFormatter().string(from:Date()));addPrivate(local);guard let client else{enqueuePrivate(input);return true};do{_ = try await client.createPrivateProduct(input);return true}catch{if error.isRetryableSyncFailure{enqueuePrivate(input);return true};items.removeAll{$0.id=="private:\(id.uuidString)"};syncError=L10n.Content.Error.network;return false}}
    func deletePrivate(_ item:InventoryItem){guard item.id.hasPrefix("private:"),let id=UUID(uuidString:String(item.id.dropFirst(8))),let client else{return};let index=items.firstIndex(where:{$0.id==item.id});if let index{items.remove(at:index)};Task{do{try await client.deletePrivateProduct(id:id)}catch{if let index{items.insert(item,at:min(index,items.count))};syncError=L10n.Content.Error.network}}}
    private func enqueue(_ mutation:InventoryMutation){guard let outboxKey else{return};let queue=(defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([InventoryMutation].self,from:$0)}) ?? [];defaults.set(try? JSONEncoder().encode(OutboxQueue.upserting(mutation,in:queue){$0.key==$1.key}),forKey:outboxKey)}
    private func pendingMutations()->[InventoryMutation]{guard let outboxKey else{return []};return defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([InventoryMutation].self,from:$0)} ?? []}
    private func replayOutbox() async {guard let client,let outboxKey,var queue=defaults.data(forKey:outboxKey).flatMap({try? JSONDecoder().decode([InventoryMutation].self,from:$0)}) else{return};for mutation in queue { do {_ = try await client.upsertInventory(.init(productId:mutation.productId,privateProductId:mutation.privateProductId,level:mutation.level.rawValue));queue.removeAll{$0.key==mutation.key}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.key==mutation.key}}} };defaults.set(try? JSONEncoder().encode(queue),forKey:outboxKey)}
    private func enqueuePrivate(_ input:PrivateProductWrite){guard let key=privateOutboxKey else{return};var queue=(defaults.data(forKey:key).flatMap{try? JSONDecoder().decode([PrivateProductWrite].self,from:$0)}) ?? [];queue.removeAll{$0.clientId==input.clientId};queue.append(input);defaults.set(try? JSONEncoder().encode(queue),forKey:key)}
    private func replayPrivateOutbox()async{guard let client,let key=privateOutboxKey,var queue=defaults.data(forKey:key).flatMap({try? JSONDecoder().decode([PrivateProductWrite].self,from:$0)})else{return};for input in queue{do{_ = try await client.createPrivateProduct(input);queue.removeAll{$0.clientId==input.clientId}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.clientId==input.clientId}}}};defaults.set(try? JSONEncoder().encode(queue),forKey:key)}

    private let defaults: any KeyValueStoring
    private func save() {
        guard let storageKey,let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

}
