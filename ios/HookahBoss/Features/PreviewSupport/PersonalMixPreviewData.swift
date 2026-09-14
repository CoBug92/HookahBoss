import Foundation

enum PersonalMixPreviewData {
    static let tropical = PersonalMixRecord(
        id: UUID(),
        title: "Tropical Mix",
        components: [
            PersonalMixComponentRecord(
                id: UUID(),
                source: .catalog,
                sourceID: "preview-mango",
                brand: "DARKSIDE",
                line: "Core",
                flavor: "Mango",
                percentage: 60,
                flavorProfiles: ["fruit"]
            ),
            PersonalMixComponentRecord(
                id: UUID(),
                source: .catalog,
                sourceID: "preview-lime",
                brand: "Musthave",
                line: nil,
                flavor: "Lime",
                percentage: 40,
                flavorProfiles: ["citrus"]
            ),
        ],
        createdAt: .now,
        isApproximate: false
    )

    static let approximate = PersonalMixRecord(
        id: UUID(),
        title: "Evening Mix",
        components: tropical.components,
        createdAt: .now,
        isApproximate: true
    )

    static let collection = [tropical, approximate]
}
