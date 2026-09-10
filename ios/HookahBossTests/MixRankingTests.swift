import XCTest
@testable import HookahBoss

final class MixRankingTests:XCTestCase {
    private func mix(_ id:Int,rating:Double?=nil,count:Int=0,personal:Int?=nil,favorite:Bool=false)->MixPreview{.init(id:UUID(uuidString:String(format:"00000000-0000-0000-0000-%012d",id))!,title:"Mix \(id)",flavorTags:[],flavorProfiles:[.fruit],sweetness:.subtle,acidity:.subtle,freshness:.subtle,ingredients:[],rating:rating,ratingsCount:count,strength:.medium,personalRating:personal,isFavorite:favorite,palette:.tropical)}
    func testPersonalSignalsPrecedeCollectiveRating(){let collective=mix(1,rating:5,count:1000),rated=mix(2,rating:2,count:2,personal:4),favorite=mix(3,rating:1,count:1,favorite:true);XCTAssertEqual(MixRanker.ranked([collective,rated,favorite]).map(\.id),[favorite.id,rated.id,collective.id])}
    func testCollectiveRatingUsesRatingsConfidence(){let sparse=mix(1,rating:5,count:1),trusted=mix(2,rating:4.5,count:100);XCTAssertEqual(MixRanker.ranked([sparse,trusted]).first?.id,trusted.id)}
    func testFeedOrderIsStableTieBreaker(){let a=mix(1,rating:4,count:10),b=mix(2,rating:4,count:10);XCTAssertEqual(MixRanker.ranked([b,a]).map(\.id),[b.id,a.id])}
    func testMixOfDayIsStableAndChangesOnNextDay(){var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!;let mixes=[mix(1),mix(2),mix(3)];let date=Date(timeIntervalSince1970:1_700_000_000);let first=MixRanker.mixOfDay(from:mixes,date:date,calendar:calendar);XCTAssertEqual(first,MixRanker.mixOfDay(from:mixes,date:date.addingTimeInterval(60),calendar:calendar));XCTAssertNotEqual(first,MixRanker.mixOfDay(from:mixes,date:calendar.date(byAdding:.day,value:1,to:date)!,calendar:calendar))}
}
