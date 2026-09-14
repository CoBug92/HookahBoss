enum ArticleDetailViewState: Equatable {
    case loading
    case content(ArticleDetailDTO)
    case failure
}
