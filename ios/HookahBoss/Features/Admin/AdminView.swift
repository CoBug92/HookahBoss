import SwiftUI

struct AdminDashboardView:View {
 let client:any AdminServing
 @StateObject private var model:AdminDashboardViewModel
 init(client:any AdminServing){self.client=client;_model=StateObject(wrappedValue:AdminDashboardViewModel(service:client))}
 var body:some View{NavigationStack{List(AdminResource.all){resource in NavigationLink{AdminResourceListView(client:client,resource:resource)}label:{AdminDashboardRow(state:model.state(for:resource),resource:resource,icon:icon(resource.path))}.listRowBackground(AppTheme.card)}.listStyle(.plain).navigationTitle(L10n.Admin.title).appScreenBackground().onAppear{model.appear()}}}
 private func icon(_ path:String)->String{switch path{case "sources":"link";case "brands":"building.2";case "lines":"square.stack.3d.up";case "flavor-tags":"tag";case "products":"leaf";case "official-mixes":"square.grid.2x2";case "articles":"doc.text";default:"arrow.triangle.swap"}}
}

private struct AdminDashboardRow:View {
 let state:AdminDashboardState;let resource:AdminResource;let icon:String
 var body:some View{HStack(spacing:12){Image(systemName:icon).foregroundStyle(AppTheme.gold).frame(width:30);VStack(alignment:.leading,spacing:3){Text(resource.title).font(.body.weight(.medium));switch state{case .loading:Text(L10n.Admin.Dashboard.loading).foregroundStyle(.secondary);case .count(let count):Text(L10n.Admin.Dashboard.items(count)).foregroundStyle(.secondary);case .failed:Text(L10n.Admin.Dashboard.unavailable).foregroundStyle(.secondary)}}.font(.caption);Spacer()}.contentShape(Rectangle())}
}

private struct AdminResourceListView:View {
 let client:any AdminServing;let resource:AdminResource
 @StateObject private var model:AdminResourceListViewModel
 @State private var create=false
 init(client:any AdminServing,resource:AdminResource){self.client=client;self.resource=resource;_model=StateObject(wrappedValue:AdminResourceListViewModel(service:client,resource:resource))}
 var body:some View {
  List {
   if model.isLoading { ProgressView().frame(maxWidth:.infinity) }
   else if model.records.isEmpty { ContentUnavailableView(L10n.Admin.empty,systemImage:"tray") }
   else { ForEach(model.records) { record in recordRow(record) } }
  }
  .navigationTitle(resource.title)
  .appScreenBackground()
  .toolbar { Button { create=true } label:{Image(systemName:"plus")}.accessibilityLabel(L10n.Admin.create) }
  .onAppear { model.appear() }
  .refreshable { await model.refresh() }
  .sheet(isPresented:$create){NavigationStack{AdminEditorView(model:AdminEditorViewModel(service:client,resource:resource,record:nil)){create=false;model.appear()}}}
  .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.errorMessage=nil}})){Button(L10n.Common.close){} }message:{Text(model.errorMessage ?? "")}
 }
 private func recordRow(_ record:AdminRecord)->some View {
  NavigationLink { AdminEditorView(model:AdminEditorViewModel(service:client,resource:resource,record:record)){model.appear()} }
  label: { VStack(alignment:.leading){Text(record.title);Text(record.id).font(.caption2).foregroundStyle(.secondary)} }
  .swipeActions {
   Button(role:.destructive){model.deleteIntent(record)}label:{Label(L10n.Common.delete,systemImage:"trash")}
   if supportsStatus {
    Button{model.statusIntent("archived",record:record)}label:{Label(L10n.Admin.archive,systemImage:"archivebox")}.tint(.orange)
    Button{model.statusIntent("published",record:record)}label:{Label(L10n.Admin.publish,systemImage:"checkmark.seal")}.tint(.green)
   }
  }
 }
 private var supportsStatus:Bool{resource.fields.contains{$0.key=="status"} && !["products","official-mixes"].contains(resource.path)}
}

private struct AdminEditorView:View {
 @Environment(\.dismiss)private var dismiss;@StateObject private var model:AdminEditorViewModel;let onSaved:()->Void
 init(model:@autoclosure @escaping()->AdminEditorViewModel,onSaved:@escaping()->Void){_model=StateObject(wrappedValue:model());self.onSaved=onSaved}
 private var resource:AdminResource{model.resource};private var record:AdminRecord?{model.record};private var components:[AdminComponentRow]{model.components};private var tags:[AdminTagRow]{model.tags};private var sections:[AdminArticleSectionRow]{model.sections};private var saving:Bool{model.saving};private var error:String?{model.error}
 var body:some View{Form{ForEach(resource.fields.filter{$0.kind != .json}){field in if field.kind == .status{Picker(field.title,selection:binding(field.key)){Text(L10n.Admin.Status.draft).tag("draft");Text(L10n.Admin.Status.published).tag("published");Text(L10n.Admin.Status.archived).tag("archived")}}else{TextField(field.title,text:binding(field.key)).textInputAutocapitalization(.never).keyboardType(field.kind == .number ? .numberPad:.default)}};if resource.path=="official-mixes"{componentEditor};if resource.path=="products"{tagEditor};if resource.path=="articles"{articleEditor};if let error{Section{Text(error).foregroundStyle(.red)}}}.navigationTitle(record == nil ? L10n.Admin.create:L10n.Admin.edit).appScreenBackground().toolbar{ToolbarItem(placement:.cancellationAction){Button(L10n.Common.cancel){dismiss()}};ToolbarItem(placement:.confirmationAction){Button(L10n.Common.save){model.saveIntent{onSaved();dismiss()}}.disabled(!model.canSave)};ToolbarItem(placement:.secondaryAction){EditButton()}}}
 private var componentEditor:some View{Section{ForEach($model.components){$row in HStack{AdminReferenceButton(model:model.referenceModel(AdminResource.all.first{$0.path=="products"}!),selection:$row.productId,label:$row.productName);TextField("%",text:$row.percentage).keyboardType(.numberPad).frame(width:48);Text("%").foregroundStyle(.secondary)}.swipeActions{Button(role:.destructive){model.removeComponent(row.id)}label:{Image(systemName:"trash")}}}.onMove{model.moveComponents(from:$0,to:$1)};Button(L10n.Admin.addComponent,systemImage:"plus"){model.addComponent()}}header:{HStack{Text(L10n.Admin.components);Spacer();Text("\(model.percentageTotal)%").foregroundStyle(model.percentageTotal==100 ? .green:.red).fontWeight(.semibold)}}}
 private var tagEditor:some View{Section(L10n.Admin.tags){ForEach($model.tags){$row in HStack{AdminReferenceButton(model:model.referenceModel(AdminResource.all.first{$0.path=="flavor-tags"}!),selection:$row.tagId,label:$row.tagName);Stepper("\(row.weight)",value:Binding(get:{Int(row.weight) ?? 1},set:{row.weight=String($0)}),in:1...5).fixedSize()}.swipeActions{Button(role:.destructive){model.removeTag(row.id)}label:{Image(systemName:"trash")}}};Button(L10n.Admin.addTag,systemImage:"plus"){model.addTag()}}}
 private var articleEditor:some View{Section(L10n.Admin.sections){ForEach($model.sections){$row in VStack(alignment:.leading,spacing:8){TextField(L10n.Admin.Section.headingRu,text:$row.headingRu);TextField(L10n.Admin.Section.bodyRu,text:$row.bodyRu,axis:.vertical).lineLimit(2...6);Divider();TextField(L10n.Admin.Section.headingEn,text:$row.headingEn);TextField(L10n.Admin.Section.bodyEn,text:$row.bodyEn,axis:.vertical).lineLimit(2...6)}.padding(.vertical,5).swipeActions{Button(role:.destructive){model.removeSection(row.id)}label:{Image(systemName:"trash")}}}.onMove{model.moveSections(from:$0,to:$1)};Button(L10n.Admin.addSection,systemImage:"plus"){model.addSection()}}}
 private func binding(_ key:String)->Binding<String>{Binding(get:{model.values[key] ?? ""},set:{model.values[key]=$0})}
 private static func snake(_ input:String)->String{input.reduce(""){result,char in char.isUppercase ? result+"_"+char.lowercased():result+String(char)}}
 private static func value(_ record:AdminRecord?,_ key:String)->JSONValue?{record?.values[key] ?? record?.values[snake(key)]}
 private static func componentRows(_ record:AdminRecord?)->[AdminComponentRow]{guard case .array(let values)=value(record,"components")else{return []};return values.compactMap{guard case .object(let o)=$0 else{return nil};return .init(productId:o["productId"]?.display ?? o["product_id"]?.display ?? "",percentage:o["percentage"]?.display ?? "")}}
 private static func tagRows(_ record:AdminRecord?)->[AdminTagRow]{guard case .array(let values)=value(record,"tags")else{return []};return values.compactMap{guard case .object(let o)=$0 else{return nil};return .init(tagId:o["tagId"]?.display ?? o["tag_id"]?.display ?? "",weight:o["weight"]?.display ?? "1")}}
 private static func sectionRows(_ record:AdminRecord?)->[AdminArticleSectionRow]{func parts(_ key:String)->[(String,String)]{guard case .array(let values)=value(record,key)else{return []};return values.compactMap{guard case .object(let o)=$0 else{return nil};return(o["heading"]?.display ?? "",o["body"]?.display ?? "")}};let ru=parts("bodyRuStructured"),en=parts("bodyEnStructured"),count=max(ru.count,en.count);return(0..<count).map{.init(headingRu:$0<ru.count ? ru[$0].0:"",bodyRu:$0<ru.count ? ru[$0].1:"",headingEn:$0<en.count ? en[$0].0:"",bodyEn:$0<en.count ? en[$0].1:"")}}
}

private struct AdminReferenceButton:View {
 @StateObject private var model:AdminReferenceViewModel;@Binding var selection:String;@Binding var label:String;@State private var show=false
  init(model:@autoclosure @escaping()->AdminReferenceViewModel,selection:Binding<String>,label:Binding<String>){_model=StateObject(wrappedValue:model());_selection=selection;_label=label}
 var body:some View{Button{show=true}label:{HStack{Text(label.isEmpty ? L10n.Admin.choose:label).lineLimit(2);Spacer();Image(systemName:"chevron.up.chevron.down")}}.sheet(isPresented:$show){AdminReferencePicker(model:model){record in selection=record.id;label=record.title;show=false}}}
}
private struct AdminReferencePicker:View {
 @Environment(\.dismiss)private var dismiss;@StateObject private var model:AdminReferenceViewModel;let select:(AdminRecord)->Void
 init(model:@autoclosure @escaping()->AdminReferenceViewModel,select:@escaping(AdminRecord)->Void){_model=StateObject(wrappedValue:model());self.select=select}
 var body:some View{NavigationStack{List(model.filtered){record in Button{select(record)}label:{VStack(alignment:.leading){Text(record.title);Text(record.id).font(.caption2).foregroundStyle(.secondary)}}}.searchable(text:$model.search).navigationTitle(model.resource.title).appScreenBackground().toolbar{Button(L10n.Common.cancel){dismiss()}}.onAppear{model.appear()}}}
}
