import Foundation

enum JSONValue:Codable,Equatable,Sendable {
    case string(String),number(Double),bool(Bool),object([String:JSONValue]),array([JSONValue]),null
    init(from decoder:Decoder)throws { let c=try decoder.singleValueContainer();if c.decodeNil(){self = .null}else if let v=try? c.decode(Bool.self){self = .bool(v)}else if let v=try? c.decode(Double.self){self = .number(v)}else if let v=try? c.decode(String.self){self = .string(v)}else if let v=try? c.decode([String:JSONValue].self){self = .object(v)}else{self = .array(try c.decode([JSONValue].self))} }
    func encode(to encoder:Encoder)throws {var c=encoder.singleValueContainer();switch self{case .string(let v):try c.encode(v);case .number(let v):try c.encode(v);case .bool(let v):try c.encode(v);case .object(let v):try c.encode(v);case .array(let v):try c.encode(v);case .null:try c.encodeNil()} }
    var display:String {switch self{case .string(let v):v;case .number(let v):v.rounded()==v ? String(Int(v)):String(v);case .bool(let v):String(v);case .null:"";case .array,.object:(try? String(data:JSONEncoder().encode(self),encoding:.utf8)) ?? ""}}
}
struct AdminCapabilitiesDTO:Codable,Equatable {let admin:Bool}
struct AdminRecord:Codable,Identifiable,Equatable {let values:[String:JSONValue];init(from decoder:Decoder)throws{values=try [String:JSONValue](from:decoder)};func encode(to encoder:Encoder)throws{try values.encode(to:encoder)};var id:String{values["id"]?.display ?? UUID().uuidString};var title:String{for key in ["name","title","titleRu","slug","url","reason"]{if let v=values[key]?.display,!v.isEmpty{return v}};return id}}

enum AdminFieldKind {case text,number,date,status,json}
struct AdminField:Identifiable {let key:String;let title:String;let kind:AdminFieldKind;let required:Bool;var id:String{key}}
struct AdminResource:Identifiable {
    let path:String;let titleKey:String;let fields:[AdminField];var id:String{path}
    static let all:[AdminResource]=[
      .init(path:"sources",titleKey:"admin.sources",fields:[.init(key:"url",title:"admin.field.url",kind:.text,required:true),.init(key:"title",title:"admin.field.title",kind:.text,required:false),.init(key:"publisher",title:"admin.field.publisher",kind:.text,required:false),.init(key:"checkedAt",title:"admin.field.checkedAt",kind:.date,required:true)]),
      .init(path:"brands",titleKey:"admin.brands",fields:content([("slug","admin.field.slug"),("name","admin.field.name")])),
      .init(path:"lines",titleKey:"admin.lines",fields:content([("brandId","admin.field.brandId"),("slug","admin.field.slug"),("name","admin.field.name"),("strength","admin.field.strength")])),
      .init(path:"flavor-tags",titleKey:"admin.tags",fields:[.init(key:"slug",title:"admin.field.slug",kind:.text,required:true),.init(key:"nameRu",title:"admin.field.nameRu",kind:.text,required:true),.init(key:"nameEn",title:"admin.field.nameEn",kind:.text,required:true),.init(key:"profile",title:"admin.field.profile",kind:.text,required:true)]),
      .init(path:"products",titleKey:"admin.products",fields:content([("lineId","admin.field.lineId"),("slug","admin.field.slug"),("name","admin.field.internalName"),("nameRu","admin.field.nameRu"),("nameEn","admin.field.nameEn"),("sweetness","admin.field.sweetness"),("acidity","admin.field.acidity"),("freshness","admin.field.freshness"),("translationOrigin","admin.field.translationOrigin"),("sourceConfidence","admin.field.sourceConfidence")])+[.init(key:"descriptionRu",title:"admin.field.descriptionRu",kind:.text,required:false),.init(key:"descriptionEn",title:"admin.field.descriptionEn",kind:.text,required:false),.init(key:"tags",title:"admin.field.tags",kind:.json,required:true)]),
      .init(path:"official-mixes",titleKey:"admin.mixes",fields:content([("slug","admin.field.slug"),("titleRu","admin.field.titleRu"),("titleEn","admin.field.titleEn")])+optional([("summaryRu","admin.field.summaryRu"),("summaryEn","admin.field.summaryEn"),("translationOrigin","admin.field.translationOrigin"),("sourceConfidence","admin.field.sourceConfidence")])+[.init(key:"components",title:"admin.field.components",kind:.json,required:true)]),
      .init(path:"articles",titleKey:"admin.articles",fields:localizedContent([("slug","admin.field.slug"),("titleRu","admin.field.titleRu"),("titleEn","admin.field.titleEn"),("summaryRu","admin.field.summaryRu"),("summaryEn","admin.field.summaryEn"),("bodyRu","admin.field.bodyRu"),("bodyEn","admin.field.bodyEn")])+[.init(key:"category",title:"admin.field.category",kind:.text,required:true),.init(key:"readingMinutes",title:"admin.field.readingMinutes",kind:.number,required:true),.init(key:"bodyRuStructured",title:"admin.field.sectionsRu",kind:.json,required:true),.init(key:"bodyEnStructured",title:"admin.field.sectionsEn",kind:.json,required:true)]),
      .init(path:"substitution-deny-rules",titleKey:"admin.denyRules",fields:[.init(key:"sourceProductId",title:"admin.field.sourceProductId",kind:.text,required:true),.init(key:"substituteProductId",title:"admin.field.substituteProductId",kind:.text,required:true),.init(key:"reason",title:"admin.field.reason",kind:.text,required:false)])
    ]
    private static func content(_ base:[(String,String)])->[AdminField]{base.map{.init(key:$0.0,title:$0.1,kind:.text,required:true)}+[.init(key:"status",title:"admin.field.status",kind:.status,required:true),.init(key:"sourceId",title:"admin.field.sourceId",kind:.text,required:false),.init(key:"verifiedAt",title:"admin.field.verifiedAt",kind:.date,required:false)]}
    private static func localizedContent(_ base:[(String,String)])->[AdminField]{content(base)}
    private static func optional(_ base:[(String,String)])->[AdminField]{base.map{.init(key:$0.0,title:$0.1,kind:.text,required:false)}}
}

enum AdminFormValidator {
 static func body(resource:AdminResource,values:[String:String])throws->[String:JSONValue] {
  var body:[String:JSONValue]=[:]
  for field in resource.fields {
   let raw=(values[field.key] ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
   if field.required && raw.isEmpty { throw ValidationError.required(field.title) }
   if raw.isEmpty { continue }
   switch field.kind {
   case .number: guard let n=Double(raw) else { throw ValidationError.invalid(field.title) };body[field.key] = .number(n)
   case .json: guard let data=raw.data(using:.utf8),let value=try? JSONDecoder().decode(JSONValue.self,from:data) else { throw ValidationError.invalid(field.title) };body[field.key] = value
   default: body[field.key] = .string(raw)
   }
  }
  if let status=values["status"],status != "draft",["published","archived"].contains(status),((values["sourceId"] ?? "").isEmpty || (values["verifiedAt"] ?? "").isEmpty) { throw ValidationError.provenance }
  if resource.path == "official-mixes",case .array(let components)=body["components"] { let total=components.reduce(0){sum,item in guard case .object(let o)=item,case .number(let n)=o["percentage"] else{return sum};return sum+Int(n)};if total != 100 { throw ValidationError.percentages } }
  return body
 }
 enum ValidationError:LocalizedError,Equatable {case required(String),invalid(String),provenance,percentages;var errorDescription:String?{switch self{case .required(let f):String(format:String(localized:"admin.validation.required"),String(localized:String.LocalizationValue(f)));case .invalid(let f):String(format:String(localized:"admin.validation.invalid"),String(localized:String.LocalizationValue(f)));case .provenance:String(localized:"admin.validation.provenance");case .percentages:String(localized:"admin.validation.percentages")}}}
}

struct AdminComponentRow:Identifiable,Equatable {let id:UUID;var productId:String;var productName:String;var percentage:String;init(id:UUID=UUID(),productId:String="",productName:String="",percentage:String=""){self.id=id;self.productId=productId;self.productName=productName;self.percentage=percentage}}
struct AdminTagRow:Identifiable,Equatable {let id:UUID;var tagId:String;var tagName:String;var weight:String;init(id:UUID=UUID(),tagId:String="",tagName:String="",weight:String="1"){self.id=id;self.tagId=tagId;self.tagName=tagName;self.weight=weight}}
struct AdminArticleSectionRow:Identifiable,Equatable {let id:UUID;var headingRu:String;var bodyRu:String;var headingEn:String;var bodyEn:String;init(id:UUID=UUID(),headingRu:String="",bodyRu:String="",headingEn:String="",bodyEn:String=""){self.id=id;self.headingRu=headingRu;self.bodyRu=bodyRu;self.headingEn=headingEn;self.bodyEn=bodyEn}}

enum AdminAggregateMapper {
 static func components(_ rows:[AdminComponentRow])throws->JSONValue { .array(try rows.map{guard !$0.productId.isEmpty,let percent=Int($0.percentage),percent>0 else{throw AdminFormValidator.ValidationError.invalid("admin.field.components")};return .object(["productId":.string($0.productId),"percentage":.number(Double(percent))])}) }
 static func tags(_ rows:[AdminTagRow])throws->JSONValue { .array(try rows.map{guard !$0.tagId.isEmpty,let weight=Int($0.weight),(1...5).contains(weight)else{throw AdminFormValidator.ValidationError.invalid("admin.field.tags")};return .object(["tagId":.string($0.tagId),"weight":.number(Double(weight))])}) }
 static func articleSections(_ rows:[AdminArticleSectionRow])throws->(ru:JSONValue,en:JSONValue){guard !rows.isEmpty,rows.allSatisfy({!$0.headingRu.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && !$0.bodyRu.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && !$0.headingEn.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && !$0.bodyEn.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty})else{throw AdminFormValidator.ValidationError.invalid("admin.sections")};return(.array(rows.map{.object(["heading":.string($0.headingRu),"body":.string($0.bodyRu)])}),.array(rows.map{.object(["heading":.string($0.headingEn),"body":.string($0.bodyEn)])}))}
 static func percentageTotal(_ rows:[AdminComponentRow])->Int{rows.compactMap{Int($0.percentage)}.reduce(0,+)}
}
