import XCTest
@testable import HookahBoss

final class AdminFormTests:XCTestCase {
 func testPublishedContentRequiresProvenance() {let resource=AdminResource.all.first{$0.path=="brands"}!;XCTAssertThrowsError(try AdminFormValidator.body(resource:resource,values:["slug":"brand","name":"Brand","status":"published"]))}
 func testOfficialMixComponentsMustTotal100(){let resource=AdminResource.all.first{$0.path=="official-mixes"}!;let values=["slug":"mix","titleRu":"Микс","titleEn":"Mix","status":"draft","components":"[{\"productId\":\"p1\",\"percentage\":60},{\"productId\":\"p2\",\"percentage\":30}]"];XCTAssertThrowsError(try AdminFormValidator.body(resource:resource,values:values))}
 func testValidDraftMixProducesStructuredComponents()throws{let resource=AdminResource.all.first{$0.path=="official-mixes"}!;let values=["slug":"mix","titleRu":"Микс","titleEn":"Mix","status":"draft","components":"[{\"productId\":\"p1\",\"percentage\":60},{\"productId\":\"p2\",\"percentage\":40}]"];let body=try AdminFormValidator.body(resource:resource,values:values);guard case .array(let components)=body["components"]else{return XCTFail()};XCTAssertEqual(components.count,2)}
 func testNativeComponentRowsMapInStableOrderAndTotal(){let rows=[AdminComponentRow(productId:"p1",percentage:"60"),AdminComponentRow(productId:"p2",percentage:"40")];XCTAssertEqual(AdminAggregateMapper.percentageTotal(rows),100);guard case .array(let encoded)=try? AdminAggregateMapper.components(rows),case .object(let first)=encoded.first else{return XCTFail()};XCTAssertEqual(first["productId"],.string("p1"))}
 func testNativeTagRowsValidateWeight(){XCTAssertThrowsError(try AdminAggregateMapper.tags([.init(tagId:"tag",weight:"6")]))}
 func testPairedArticleSectionsMapToBothLocales()throws{let mapped=try AdminAggregateMapper.articleSections([.init(headingRu:"Жар",bodyRu:"Текст",headingEn:"Heat",bodyEn:"Body")]);guard case .array(let ru)=mapped.ru,case .array(let en)=mapped.en else{return XCTFail()};XCTAssertEqual(ru.count,1);XCTAssertEqual(en.count,1)}
}
