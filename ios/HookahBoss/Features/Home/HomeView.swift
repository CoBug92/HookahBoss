import SwiftUI

struct HomeView: View {
    @StateObject private var model: HomeViewModel
    var onFindMix:()->Void = {}
    var onInventory:()->Void = {}
    var onProfile:()->Void = {}
    let makeMixDetailModel: (MixPreview) -> MixDetailViewModel
    init(model: @autoclosure @escaping () -> HomeViewModel, onFindMix: @escaping () -> Void = {}, onInventory: @escaping () -> Void = {}, onProfile: @escaping () -> Void = {}, makeMixDetailModel: @escaping (MixPreview) -> MixDetailViewModel) {
        _model = StateObject(wrappedValue: model()); self.onFindMix = onFindMix; self.onInventory = onInventory; self.onProfile = onProfile; self.makeMixDetailModel = makeMixDetailModel
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    hero
                    quickActions
                    recommendations
                }
                .padding(.horizontal, 18).padding(.top, 4).padding(.bottom, 34)
            }
            .background(background.ignoresSafeArea())
            .navigationTitle(L10n.Home.question)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onProfile) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.gold)
                    }
                    .accessibilityLabel(Text(L10n.Home.profile))
                    .accessibilityIdentifier(AccessibilityID.homeLogin)
                }
            }
            .navigationDestination(for:MixPreview.self){MixDetailView(model:makeMixDetailModel($0))}
        }.onAppear{model.syncLibraryState()}.accessibilityIdentifier("screen.home")
    }

    private var background: Color { AppTheme.background }

    private var hero: some View {
        Group { if let mix=model.mixOfDay { NavigationLink(value:mix) {
            MixArtwork(palette: mix.palette)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .overlay {
                    LinearGradient(colors:[.black.opacity(0.06),.black.opacity(0.88)],startPoint:.top,endPoint:.bottom)
                }
                .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Home.mixOfDay)
                        .font(.caption.weight(.bold)).textCase(.uppercase).foregroundStyle(AppTheme.cream)
                    Text(mix.title)
                        .font(.system(size: 27, weight: .bold, design: .serif))
                        .tracking(-0.5)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    HStack(spacing: 5) {
                        ForEach(Array(mix.flavorTags.prefix(3)), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.16), in: Capsule())
                        }
                    }
                    HStack { if let rating=mix.rating { Label(rating.formatted(.number.precision(.fractionLength(1))),systemImage:"star.fill") }; Spacer(); Text(mix.strength.title) }.font(.caption).foregroundStyle(.white.opacity(0.72))
                }
                .foregroundStyle(.white)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
                }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color:.black.opacity(0.16),radius:20,y:10)
        }.buttonStyle(.plain) } else { RoundedRectangle(cornerRadius:26).fill(AppTheme.card).frame(height:280).overlay{ProgressView()} } }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickAction(title: L10n.Home.findMix, icon: "slider.horizontal.3", emphasized: true, action:onFindMix)
                .accessibilityIdentifier(AccessibilityID.homeFindMix)
            QuickAction(title: L10n.Inventory.findMixes, icon: "shippingbox.fill", emphasized: false, action:onInventory)
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment:.firstTextBaseline) {
                Text(L10n.Home.recommended).font(.title3.weight(.bold))
            }

            LazyVStack(spacing: 10) {
                ForEach(model.recommendations) { mix in
                    NavigationLink(value: mix) { MixCardView(mix: mix) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.homeRecommendation(mix.id))
                }
            }
        }
        .task { await model.appear() }
    }
}

private struct QuickAction: View {
    let title: String
    let icon: String
    let emphasized: Bool
    let action:()->Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3).frame(width:34,height:34).background(emphasized ? Color.white.opacity(0.14):AppTheme.gold.opacity(0.12),in:RoundedRectangle(cornerRadius:10))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .padding(16)
            .foregroundStyle(emphasized ? Color.white : Color.primary)
            .background(emphasized ? AppTheme.gold : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay{RoundedRectangle(cornerRadius:18).stroke(emphasized ? .clear:Color.primary.opacity(0.07))}
        }
        .buttonStyle(.plain)
    }
}
