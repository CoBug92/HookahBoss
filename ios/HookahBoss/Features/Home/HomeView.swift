import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigation:AppNavigation
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
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    hero
                    quickActions
                    recommendations
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for:MixPreview.self){MixDetailView(model:makeMixDetailModel($0))}
        }.accessibilityIdentifier("screen.home")
    }

    private var background: Color { AppTheme.background }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Home.greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(L10n.Home.question)
                    .font(.largeTitle.weight(.semibold))
            }

            Spacer()

            Button(action: onProfile) {
                Image(systemName: "person.crop.circle")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Home.profile))
        }
        .padding(.top, 12)
    }

    private var hero: some View {
        Group { if let mix=model.mixOfDay { NavigationLink(value:mix) {
            ZStack(alignment: .bottomLeading) {
                MixArtwork(palette: mix.palette)
                LinearGradient(colors:[.black.opacity(0.06),.black.opacity(0.88)],startPoint:.top,endPoint:.bottom)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Home.mixOfDay)
                        .font(.caption.weight(.bold)).textCase(.uppercase).foregroundStyle(AppTheme.cream)
                    Text(mix.title)
                        .font(.title2.weight(.semibold))
                    Text(mix.flavorTags.joined(separator:" · "))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .frame(height: 178)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }.buttonStyle(.plain) } else { RoundedRectangle(cornerRadius:26).fill(AppTheme.card).frame(height:178).overlay{ProgressView()} } }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickAction(title: L10n.Home.findMix, icon: "slider.horizontal.3", emphasized: true, action:onFindMix)
            QuickAction(title: L10n.Inventory.findMixes, icon: "shippingbox.fill", emphasized: false, action:onInventory)
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Home.recommended)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(L10n.Common.all) { navigation.openMixFinder() }
                    .foregroundStyle(AppTheme.gold)
            }

            ForEach(model.recommendations) { mix in
                MixRow(mix: mix)
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
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .padding(16)
            .foregroundStyle(emphasized ? Color.white : Color.primary)
            .background(emphasized ? AppTheme.gold : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MixRow: View {
    let mix: MixPreview

    var body: some View {
        HStack(spacing: 12) {
            MixArtwork(palette: mix.palette)
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text(mix.title)
                    .font(.headline)
                Text(mix.flavorTags.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let rating = mix.rating {
                Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .padding(10)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
