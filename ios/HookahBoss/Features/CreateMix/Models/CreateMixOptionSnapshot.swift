struct CreateMixOptionSnapshot: Equatable, Sendable {
    let catalog: [CreateMixProduct]
    let personal: [CreateMixProduct]
    let inventory: [CreateMixProduct]
}
