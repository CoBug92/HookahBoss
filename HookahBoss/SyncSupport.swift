import Foundation

extension Error {
    var isRetryableSyncFailure: Bool {
        if let api=self as? APIError,case .http(let status, _, _) = api { return status >= 500 || status == 408 || status == 429 }
        if self is AuthTokenError { return false }
        return true
    }
}

enum SyncFailurePolicy {
    enum Disposition:Equatable { case queue,rollback }
    static func disposition(for error:Error)->Disposition { error.isRetryableSyncFailure ? .queue:.rollback }
}

enum OutboxQueue {
    static func upserting<Item>(_ item:Item,in items:[Item],matches:(Item,Item)->Bool)->[Item] { items.filter{!matches($0,item)} + [item] }
    static func removing<Item,ID:Equatable>(_ id:ID,from items:[Item],id keyPath:KeyPath<Item,ID>)->[Item] { items.filter{$0[keyPath:keyPath] != id} }
}

struct LibraryMutation:Codable,Equatable,Identifiable {
    enum Kind:String,Codable { case favorite,rating }
    let id:UUID;let kind:Kind;let mixId:UUID;let value:Int?
}
struct InventoryMutation:Codable,Equatable { let productId:UUID?;let privateProductId:UUID?;let level:InventoryLevel;var key:String{productId?.uuidString ?? "private:\(privateProductId?.uuidString ?? "")"} }
struct BookmarkMutation:Codable,Equatable { let slug:String;let enabled:Bool }
struct PrivateProductMutation:Codable,Equatable { let input:PrivateProductWrite }
enum InventoryProjection {
    static func overlay(levels:[UUID:InventoryLevel],pending:[InventoryMutation])->[UUID:InventoryLevel] { var result=levels;for mutation in pending{if let id=mutation.productId{result[id]=mutation.level}};return result }
}

struct LibraryProjection:Equatable {
    var favorites:Set<UUID>;var ratings:[UUID:Int]
    func overlaying(_ mutations:[LibraryMutation])->Self { var result=self;for mutation in mutations {switch mutation.kind{case .favorite:if mutation.value==1{result.favorites.insert(mutation.mixId)}else{result.favorites.remove(mutation.mixId)};case .rating:result.ratings[mutation.mixId]=mutation.value}};return result }
}

enum PersonalMixReconciler {
    static func merge(server:[PersonalMixRecord],cached:[PersonalMixRecord],pending:[PersonalMixRecord])->[PersonalMixRecord] {
        var result=server.map{ remote in cached.first(where:{$0.id==remote.id}) ?? remote }
        for item in pending where !result.contains(where:{$0.id==item.id}) { result.insert(item,at:0) }
        return result
    }
}
