import XCTest
@testable import HookahBoss

final class SyncSupportTests:XCTestCase {
    func testTransientQueuesButValidationRollsBack(){
        XCTAssertEqual(SyncFailurePolicy.disposition(for:APIError.transport("offline")),.queue)
        XCTAssertEqual(SyncFailurePolicy.disposition(for:APIError.http(status:503,serverCode:nil,body:Data())),.queue)
        XCTAssertEqual(SyncFailurePolicy.disposition(for:APIError.http(status:429,serverCode:nil,body:Data())),.queue)
        XCTAssertEqual(SyncFailurePolicy.disposition(for:APIError.http(status:400,serverCode:"invalid",body:Data())),.rollback)
    }
    func testOutboxCoalescesSameIntentWithoutChangingOtherRetryOrderAndRemovesAcknowledged(){
        let a=UUID(),b=UUID();let first=LibraryMutation(id:UUID(),kind:.favorite,mixId:a,value:1),second=LibraryMutation(id:UUID(),kind:.rating,mixId:b,value:3),replacement=LibraryMutation(id:UUID(),kind:.favorite,mixId:a,value:0)
        let queue=OutboxQueue.upserting(replacement,in:[first,second]){$0.kind==$1.kind && $0.mixId==$1.mixId}
        XCTAssertEqual(queue.map(\.id),[second.id,replacement.id])
        XCTAssertEqual(OutboxQueue.removing(second.id,from:queue,id:\.id),[replacement])
    }
    func testPendingLibraryIntentOverlaysOlderServerSnapshot(){
        let mix=UUID();let server=LibraryProjection(favorites:[],ratings:[mix:2]);let pending=[LibraryMutation(id:UUID(),kind:.favorite,mixId:mix,value:1),LibraryMutation(id:UUID(),kind:.rating,mixId:mix,value:5)]
        XCTAssertEqual(server.overlaying(pending),LibraryProjection(favorites:[mix],ratings:[mix:5]))
    }
    func testInventorySnapshotCannotErasePendingLevel(){
        let product=UUID();let result=InventoryProjection.overlay(levels:[product:.empty],pending:[.init(productId:product,privateProductId:nil,level:.plenty)])
        XCTAssertEqual(result[product],.plenty)
    }
    func testPersonalReconcilePreservesCachedTitleComponentsAndDoesNotDuplicatePending(){
        let id=UUID(),component=PersonalMixComponentRecord(id:UUID(),source:.catalog,sourceID:UUID().uuidString,brand:"B",line:"L",flavor:"F",percentage:100)
        let cached=PersonalMixRecord(id:id,title:"Local",components:[component],createdAt:.distantPast)
        let sparseServer=PersonalMixRecord(id:id,title:"Server",components:[],createdAt:.distantFuture)
        let merged=PersonalMixReconciler.merge(server:[sparseServer],cached:[cached],pending:[cached])
        XCTAssertEqual(merged.count,1);XCTAssertEqual(merged[0].title,"Local");XCTAssertEqual(merged[0].components,[component])
    }
    func testCreateWriteCarriesStableClientIdAndMaterializedPercentages() throws {
        let id=UUID();let write=PersonalMixWrite(clientId:id,title:"Mix",score:nil,comment:nil,components:[.init(productId:UUID(),privateProductId:nil,freeformName:nil,percentage:34),.init(productId:UUID(),privateProductId:nil,freeformName:nil,percentage:33),.init(productId:UUID(),privateProductId:nil,freeformName:nil,percentage:33)])
        let json=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(write)) as? [String:Any]);XCTAssertEqual(json["clientId"] as? String,id.uuidString)
        let components=try XCTUnwrap(json["components"] as? [[String:Any]]);XCTAssertEqual(components.compactMap{$0["percentage"] as? Int}.reduce(0,+),100)
    }
    func testAccountDeletionPurgesDurableOutboxes(){
        let defaults=UserDefaults(suiteName:"OutboxPurgeTests")!;defaults.removePersistentDomain(forName:"OutboxPurgeTests");let id=UUID()
        for base in ["library.outbox.v1","inventory.outbox.v1","personal.outbox.v1"]{defaults.set(Data([1]),forKey:AccountCache.key(base,accountId:id))}
        AccountCache.purge(accountId:id,defaults:defaults)
        for base in ["library.outbox.v1","inventory.outbox.v1","personal.outbox.v1"]{XCTAssertNil(defaults.data(forKey:AccountCache.key(base,accountId:id)))}
    }
    func testInventoryMatchCacheDistinguishesSuccessfulEmptyFromNoCacheAndIsAccountScoped() {
        let defaults=UserDefaults(suiteName:"InventoryMatchCacheTests")!;defaults.removePersistentDomain(forName:"InventoryMatchCacheTests")
        let first=UUID(),second=UUID()
        XCTAssertNil(InventoryMatchCache.load(accountId:first,defaults:defaults))
        InventoryMatchCache.save([],accountId:first,defaults:defaults)
        XCTAssertEqual(InventoryMatchCache.load(accountId:first,defaults:defaults),[])
        XCTAssertNil(InventoryMatchCache.load(accountId:second,defaults:defaults))
    }
    func testOutboxKeysAreAccountIsolated(){let first=UUID(),second=UUID();XCTAssertNotEqual(AccountCache.key("library.outbox.v1",accountId:first),AccountCache.key("library.outbox.v1",accountId:second))}
}
