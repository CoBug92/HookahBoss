import XCTest
@testable import HookahBoss

final class MixRankingTests:XCTestCase {
    private func mix(_ id:Int,rating:Double?=nil,count:Int=0,personal:Int?=nil,favorite:Bool=false)->MixPreview{.init(id:UUID(uuidString:String(format:"00000000-0000-0000-0000-%012d",id))!,title:"Mix \(id)",flavorTags:[],flavorProfiles:[.fruit],sweetness:.subtle,acidity:.subtle,freshness:.subtle,ingredients:[],rating:rating,ratingsCount:count,strength:.medium,personalRating:personal,isFavorite:favorite,palette:.tropical)}
    func testPersonalSignalsPrecedeCollectiveRating(){let collective=mix(1,rating:5,count:1000),rated=mix(2,rating:2,count:2,personal:4),favorite=mix(3,rating:1,count:1,favorite:true);XCTAssertEqual(MixRanker.ranked([collective,rated,favorite]).map(\.id),[favorite.id,rated.id,collective.id])}
    func testCollectiveRatingUsesRatingsConfidence(){let sparse=mix(1,rating:5,count:1),trusted=mix(2,rating:4.5,count:100);XCTAssertEqual(MixRanker.ranked([sparse,trusted]).first?.id,trusted.id)}
    func testFeedOrderIsStableTieBreaker(){let a=mix(1,rating:4,count:10),b=mix(2,rating:4,count:10);XCTAssertEqual(MixRanker.ranked([b,a]).map(\.id),[b.id,a.id])}
    func testCollectiveProjectionHandlesCreateChangeAndDelete(){let initial=mix(1,rating:4,count:1);let created=initial.applyingPersonalRatingChange(from:nil,to:2);XCTAssertEqual(created.rating,3);XCTAssertEqual(created.ratingsCount,2);let changed=created.applyingPersonalRatingChange(from:2,to:5);XCTAssertEqual(changed.rating,4.5);XCTAssertEqual(changed.ratingsCount,2);let deleted=changed.applyingPersonalRatingChange(from:5,to:nil);XCTAssertEqual(deleted.rating,4);XCTAssertEqual(deleted.ratingsCount,1)}
    func testRemovingOnlyRatingProducesUnratedMix(){let initial=mix(1,rating:3,count:1,personal:3);let result=initial.applyingPersonalRatingChange(from:3,to:nil);XCTAssertNil(result.rating);XCTAssertEqual(result.ratingsCount,0);XCTAssertNil(result.personalRating)}
    func testMixOfDayIsStableAndChangesOnNextDay(){var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!;let mixes=[mix(1),mix(2),mix(3)];let date=Date(timeIntervalSince1970:1_700_000_000);let first=MixRanker.mixOfDay(from:mixes,date:date,calendar:calendar);XCTAssertEqual(first,MixRanker.mixOfDay(from:mixes,date:date.addingTimeInterval(60),calendar:calendar));XCTAssertNotEqual(first,MixRanker.mixOfDay(from:mixes,date:calendar.date(byAdding:.day,value:1,to:date)!,calendar:calendar))}
    func testDailyRecommendationsContainTenAndRotateOnNextDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let mixes = (1...12).map { mix($0) }
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let today = MixRanker.dailyRecommendations(from: mixes, date: date, calendar: calendar)
        let sameDay = MixRanker.dailyRecommendations(from: mixes, date: date.addingTimeInterval(60), calendar: calendar)
        let tomorrow = MixRanker.dailyRecommendations(
            from: mixes,
            date: calendar.date(byAdding: .day, value: 1, to: date)!,
            calendar: calendar
        )
        XCTAssertEqual(today.count, 10)
        XCTAssertEqual(today, sameDay)
        XCTAssertNotEqual(today, tomorrow)
    }
}
