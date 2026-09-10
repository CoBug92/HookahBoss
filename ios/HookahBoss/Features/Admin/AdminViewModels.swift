import Foundation

@MainActor
final class AdminResourceListViewModel: ObservableObject {
    @Published private(set) var records: [AdminRecord] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: any AdminServing
    let resource: AdminResource

    init(service: any AdminServing, resource: AdminResource) {
        self.service = service
        self.resource = resource
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await service.adminList(resource)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func appear() { Task { await load() } }
    func refresh() async { await load() }
    func deleteIntent(_ record: AdminRecord) { Task { await remove(record) } }
    func statusIntent(_ status: String, record: AdminRecord) { Task { await setStatus(status, for: record) } }

    func setStatus(_ status: String, for record: AdminRecord) async {
        var body: [String: JSONValue] = ["status": .string(status)]
        for key in ["sourceId", "source_id", "verifiedAt", "verified_at"] {
            guard let value = record.values[key] else { continue }
            body[key == "source_id" ? "sourceId" : key == "verified_at" ? "verifiedAt" : key] = value
        }
        do {
            _ = try await service.adminUpdate(resource, id: record.id, body: body)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ record: AdminRecord) async {
        let body: [String: JSONValue]? = resource.path == "substitution-deny-rules"
            ? ["sourceProductId": record.values["sourceProductId"] ?? record.values["source_product_id"] ?? .null,
               "substituteProductId": record.values["substituteProductId"] ?? record.values["substitute_product_id"] ?? .null]
            : nil
        do {
            try await service.adminDelete(resource, id: record.id, body: body)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor final class AdminDashboardViewModel:ObservableObject {
 @Published private(set)var counts:[String:Int]=[:];@Published private(set)var failed:Set<String>=[];private let service:any AdminServing
 init(service:any AdminServing){self.service=service}
 func appear(){for resource in AdminResource.all{Task{await count(resource)}}}
 func state(for resource:AdminResource)->AdminDashboardState{if let count=counts[resource.path]{.count(count)}else if failed.contains(resource.path){.failed}else{.loading}}
 private func count(_ resource:AdminResource)async{do{counts[resource.path]=try await service.adminList(resource).count;failed.remove(resource.path)}catch{failed.insert(resource.path)}}
}
enum AdminDashboardState{case loading,count(Int),failed}

@MainActor final class AdminEditorViewModel:ObservableObject {
 @Published var values:[String:String];@Published var components:[AdminComponentRow];@Published var tags:[AdminTagRow];@Published var sections:[AdminArticleSectionRow];@Published private(set)var saving=false;@Published var error:String?
 let resource:AdminResource;let record:AdminRecord?;private let service:any AdminServing
 init(service:any AdminServing,resource:AdminResource,record:AdminRecord?){self.service=service;self.resource=resource;self.record=record;var initial:[String:String]=[:];for field in resource.fields where field.kind != .json{initial[field.key]=Self.value(record,field.key)?.display ?? ""};if resource.fields.contains(where:{$0.key=="status"}),initial["status"]?.isEmpty != false{initial["status"]="draft"};values=initial;components=Self.componentRows(record);tags=Self.tagRows(record);sections=Self.sectionRows(record)}
 var percentageTotal:Int{AdminAggregateMapper.percentageTotal(components)};var canSave:Bool{!saving&&(resource.path != "official-mixes"||percentageTotal==100)}
 func addComponent(){components.append(.init())};func removeComponent(_ id:UUID){components.removeAll{$0.id==id}};func moveComponents(from:IndexSet,to:Int){components.move(fromOffsets:from,toOffset:to)}
 func addTag(){tags.append(.init())};func removeTag(_ id:UUID){tags.removeAll{$0.id==id}}
 func addSection(){sections.append(.init())};func removeSection(_ id:UUID){sections.removeAll{$0.id==id}};func moveSections(from:IndexSet,to:Int){sections.move(fromOffsets:from,toOffset:to)}
 func saveIntent(onSuccess:@escaping()->Void){Task{if await save(){onSuccess()}}}
 func referenceModel(_ resource:AdminResource)->AdminReferenceViewModel{AdminReferenceViewModel(service:service,resource:resource)}
 func save()async->Bool{saving=true;defer{saving=false};do{var prepared=values;if resource.path=="official-mixes"{prepared["components"]=try AdminAggregateMapper.components(components).display}else if resource.path=="products"{prepared["tags"]=try AdminAggregateMapper.tags(tags).display}else if resource.path=="articles"{let mapped=try AdminAggregateMapper.articleSections(sections);prepared["bodyRuStructured"]=mapped.ru.display;prepared["bodyEnStructured"]=mapped.en.display};let body=try AdminFormValidator.body(resource:resource,values:prepared);if let record{_ = try await service.adminUpdate(resource,id:record.id,body:body)}else{_ = try await service.adminCreate(resource,body:body)};error=nil;return true}catch{self.error=error.localizedDescription;return false}}
 private static func snake(_ input:String)->String{input.reduce(""){result,char in char.isUppercase ? result+"_"+char.lowercased():result+String(char)}};private static func value(_ record:AdminRecord?,_ key:String)->JSONValue?{record?.values[key] ?? record?.values[snake(key)]}
 private static func componentRows(_ record:AdminRecord?)->[AdminComponentRow]{guard case .array(let list)=value(record,"components")else{return []};return list.compactMap{guard case .object(let o)=$0 else{return nil};return .init(productId:o["productId"]?.display ?? o["product_id"]?.display ?? "",percentage:o["percentage"]?.display ?? "")}}
 private static func tagRows(_ record:AdminRecord?)->[AdminTagRow]{guard case .array(let list)=value(record,"tags")else{return []};return list.compactMap{guard case .object(let o)=$0 else{return nil};return .init(tagId:o["tagId"]?.display ?? o["tag_id"]?.display ?? "",weight:o["weight"]?.display ?? "1")}}
 private static func sectionRows(_ record:AdminRecord?)->[AdminArticleSectionRow]{func parts(_ key:String)->[(String,String)]{guard case .array(let list)=value(record,key)else{return []};return list.compactMap{guard case .object(let o)=$0 else{return nil};return(o["heading"]?.display ?? "",o["body"]?.display ?? "")}};let ru=parts("bodyRuStructured"),en=parts("bodyEnStructured"),count=max(ru.count,en.count);return(0..<count).map{.init(headingRu:$0<ru.count ? ru[$0].0:"",bodyRu:$0<ru.count ? ru[$0].1:"",headingEn:$0<en.count ? en[$0].0:"",bodyEn:$0<en.count ? en[$0].1:"")}}
}

@MainActor final class AdminReferenceViewModel:ObservableObject {
 @Published private(set)var records:[AdminRecord]=[];@Published var search="";private let service:any AdminServing;let resource:AdminResource
 init(service:any AdminServing,resource:AdminResource){self.service=service;self.resource=resource};var filtered:[AdminRecord]{records.filter{search.isEmpty||$0.title.localizedCaseInsensitiveContains(search)}};func appear(){Task{records=(try? await service.adminList(resource)) ?? []}}
}
