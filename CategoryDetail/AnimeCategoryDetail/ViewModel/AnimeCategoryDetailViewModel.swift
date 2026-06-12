//
//  AnimeCategoryDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/2.
//

import Foundation
import Combine

@MainActor
final class AnimeCategoryDetailViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(items: [AnimeCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedSort: AnimeCategoryFilter.Sort = .default
    @Published var selectedFormat: AnimeCategoryFilter.Format = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    let genre: AnimeListGenreDTO

    private let service: AnimeCategoryDetailServicing

    // MARK: - Pagination State

    private let pageSize = 24
    private var pagination = PaginatedListState<AnimeCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []
    private var filterRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        genre: AnimeListGenreDTO,
        service: AnimeCategoryDetailServicing
    ) {
        self.genre = genre
        self.service = service
        bindPresentation()
    }

    // MARK: - Derived State

    var genreTitle: String {
        genre.name ?? "未分類"
    }

    var headerSubtitle: String {
        headerSubtitle(for: genreTitle)
    }

    var loadedCountText: String {
        "已載入 \(pagination.items.count) 部"
    }

    // MARK: - Public Methods

    func loadIfNeeded() async {
        guard !pagination.hasLoaded else { return }
        await fetchFirstPage(showSkeleton: true)
    }

    func reload() async {
        await fetchFirstPage(showSkeleton: true)
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func loadMoreIfNeeded(currentItem item: AnimeCategoryItemDTO) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    // MARK: - Filter Binding

    private var currentFilter: AnimeCategoryFilter {
        AnimeCategoryFilter(sort: selectedSort, format: selectedFormat)
    }

    private func bindPresentation() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] _, _ in
            guard let self, self.pagination.hasLoaded else { return }
            self.filterRequestTask?.cancel()
            self.filterRequestTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchFirstPage(showSkeleton: true)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Loading

    private func fetchFirstPage(showSkeleton: Bool) async {
        let generation = pagination.beginReload(clearItems: showSkeleton)
        filterRequestTask = nil

        if showSkeleton {
            screenState = .loading
            loadMoreState = pagination.footerState
        }

        do {
            let page = try await service.fetchInitialPage(
                genreId: genre.id,
                pageSize: pageSize,
                filter: currentFilter
            )
            guard pagination.finishReload(
                PaginatedPage(
                    items: page.items,
                    currentPage: page.currentPage,
                    hasNextPage: page.hasNextPage
                ),
                generation: generation
            ) else { return }
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard pagination.isCurrent(generation) else { return }
            screenState = .error(FeatureLoadFailure(error))
            loadMoreState = pagination.footerState
        }
    }

    private func loadMorePage() async {
        guard let generation = pagination.beginLoadMore() else { return }
        loadMoreState = pagination.footerState

        do {
            let page = try await service.fetchPage(
                genreId: genre.id,
                page: pagination.currentPage + 1,
                pageSize: pageSize,
                filter: currentFilter
            )
            guard pagination.finishLoadMore(
                PaginatedPage(
                    items: page.items,
                    currentPage: page.currentPage,
                    hasNextPage: page.hasNextPage
                ),
                generation: generation
            ) else { return }
            applyPresentation()
        } catch is CancellationError {
            if pagination.cancelLoadMore(generation: generation) {
                loadMoreState = pagination.footerState
            }
            return
        } catch {
            guard pagination.failLoadMore(FeatureLoadFailure.loadMore(), generation: generation) else { return }
            loadMoreState = pagination.footerState
        }
    }

    private func applyPresentation() {
        guard !pagination.items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(items: pagination.items)
        loadMoreState = pagination.footerState
    }

    private func shouldLoadMore(after item: AnimeCategoryItemDTO) -> Bool {
        guard case .content(let items) = screenState else { return false }
        return pagination.shouldLoadMore(after: item, visibleItems: items)
    }

    private func headerSubtitle(for genreTitle: String) -> String {
        switch genreTitle {
        case "動作":
            return "節奏俐落、衝突直接、看點滿滿的動作作品都集中在這裡，適合先找最能帶起情緒的熱血選擇。"
        case "冒險":
            return "從啟程、探索到未知世界的展開都收在這裡，適合慢慢挑一部能陪你走很遠的冒險故事。"
        case "前衛":
            return "敘事、畫面或節奏都更實驗性的作品會聚在這裡，想找不按常理出牌的動畫可以從這區開始。"
        case "得獎作品":
            return "這裡整理的是曾被肯定、完成度高的得獎作品，想先看品質穩定的代表作會很適合。"
        case "BL":
            return "以男性角色關係為核心的情感作品都在這裡，適合依氛圍與角色張力慢慢挑。"
        case "喜劇":
            return "不管是吐槽節奏、日常鬧劇還是誇張反差，這一區都適合找能讓人快速進入狀態的輕鬆作品。"
        case "劇情":
            return "以人物、情緒與故事推進為重心的作品集中在這裡，想找能一路投入的敘事型動畫可以先看這區。"
        case "奇幻":
            return "從異世界設定到魔法世界觀，所有帶有幻想色彩的作品都整理在這裡，適合先挑最對味的世界。"
        case "GL":
            return "以女性角色關係與情感發展為主軸的作品都在這裡，適合慢慢找角色互動最打動你的那一部。"
        case "美食":
            return "把料理、味覺與餐桌氛圍當成主角的作品都收在這裡，想看得舒服又容易餓就從這區開始。"
        case "恐怖":
            return "無論是心理壓迫、怪異氛圍還是直接驚嚇，這裡都適合先找最能讓你不安的恐怖作品。"
        case "推理":
            return "線索、伏筆與解謎樂趣都集中在這裡，想挑一部能邊看邊猜的作品可以先從這區下手。"
        case "戀愛":
            return "心動、拉扯與關係升溫的作品都在這裡，適合依角色化學反應挑一部最對你胃口的戀愛故事。"
        case "科幻":
            return "科技、未來、宇宙與想像力交會的作品都整理在這裡，適合先找設定最吸引你的那一部。"
        case "日常":
            return "節奏舒服、情緒穩定、能陪你慢慢看的日常作品都集中在這裡，適合找一部放鬆追下去。"
        case "運動":
            return "從競技張力到團隊成長，所有能把熱血感拉滿的運動作品都在這裡，適合先挑最想投入的賽場。"
        case "超自然":
            return "超出現實規則的力量、事件與存在都收在這裡，想看帶點神秘感的展開可以先看這區。"
        case "懸疑":
            return "未知、壓力與一步步逼近真相的氛圍作品都在這裡，適合找一部能一路吊著你看的故事。"
        case "賣肉":
            return "視覺張力與曖昧演出較強的作品都會收進這裡，適合依節奏與風格挑一部最合口味的作品。"
        case "情色":
            return "更偏成人情慾表現的作品整理在這裡，適合在明確知道自己想找的氛圍時再往下探索。"
        case "成人":
            return "成人取向明確、表現尺度更高的作品集中在這裡，適合依題材與接受度慎選觀看。"
        case "成人主角":
            return "主角群更接近出社會後的人生階段，這裡適合找職場、關係與現實議題更成熟的作品。"
        case "擬人":
            return "把動物、物件或概念轉化成人物魅力的作品都在這裡，適合找設定有巧思的作品來看。"
        case "可愛女孩日常":
            return "輕鬆、可愛、看完會心情變好的女孩日常作品都收在這裡，想找舒服陪伴感可以先看這區。"
        case "育兒":
            return "圍繞照顧、陪伴與家庭互動的作品都在這裡，適合想看溫柔關係與成長日常的時候打開。"
        case "格鬥":
            return "拳拳到肉、勝負明快的對抗作品集中在這裡，適合先挑一部節奏俐落的硬派作品。"
        case "變裝":
            return "身份、外表與角色切換帶來的趣味都在這裡，適合找設定鮮明、互動有反差的作品。"
        case "不良少年":
            return "衝突、友情與年少鋒芒兼具的作品都整理在這裡，適合想看角色氣場強烈的故事。"
        case "偵探":
            return "調查、推論與真相追查的作品都收在這裡，喜歡一點點職業感和案件節奏的人可以先看。"
        case "教育":
            return "帶有知識傳達、學習或啟發性的作品都在這裡，適合想找內容有吸收感的作品時探索。"
        case "搞笑":
            return "重點就是節奏、梗感與笑點爆發，想找一部不用太多負擔就能快速進入狀態的作品可以看這區。"
        case "獵奇":
            return "視覺衝擊與殘酷氛圍更強的作品集中在這裡，適合明確想挑重口味題材時再往下看。"
        case "後宮":
            return "多位角色圍繞主角發展關係的作品都在這裡，適合依角色組合與互動火花慢慢挑。"
        case "高風險遊戲":
            return "把規則、博弈與生存壓力綁在一起的作品都整理在這裡，想看高張力對決很適合先看這區。"
        case "歷史":
            return "帶有時代背景與歷史質感的作品都集中在這裡，適合先找一部能讓你沉進年代氛圍的作品。"
        case "女偶像":
            return "舞台、練習、成長與團體魅力兼具的女偶像作品都在這裡，適合先挑風格最對味的一組。"
        case "男偶像":
            return "角色魅力、舞台表現與團體互動是這區主打，想找一部節奏亮眼的男偶像作品可以先看。"
        case "異世界":
            return "轉移、召喚與重新開始的人生題材都在這裡，想找設定鮮明又容易追的作品可以先從這區挑。"
        case "療癒":
            return "節奏柔和、情緒穩定、看完會慢慢鬆下來的作品都集中在這裡，適合想被好好安放的時候打開。"
        case "多角戀":
            return "感情線交錯、立場拉扯明顯的作品都在這裡，適合想看角色關係複雜一點的戀愛故事。"
        case "性轉":
            return "身份轉換帶來的反差、笑點與新視角都在這裡，適合找設定有趣又有話題感的作品。"
        case "魔法少女":
            return "變身、使命與少女成長交會的作品都收在這裡，從經典王道到黑暗變奏都值得慢慢挑。"
        case "武術":
            return "招式、修練與身體對抗感更突出的作品都在這裡，適合先找一部動作設計夠紮實的作品。"
        case "機甲":
            return "駕駛、兵器與巨大機體的魅力都收在這裡，想看世界觀與戰鬥同樣有份量的作品可以先看。"
        case "醫療":
            return "醫術、判斷與生命現場的壓力感都集中在這裡，適合喜歡專業題材的人深入探索。"
        case "軍事":
            return "戰略、組織與衝突規模更明確的作品都在這裡，想看局勢感強烈的故事可以從這區開始。"
        case "音樂":
            return "樂團、演奏、創作與舞台魅力兼具的作品都收在這裡，適合先挑最能打中你聽感的一部。"
        case "神話":
            return "神明、傳說與古老意象延伸出的作品都在這裡，適合想找世界觀自帶厚度的故事。"
        case "黑道":
            return "地下秩序、勢力關係與危險氣場兼具的作品都集中在這裡，適合想看張力更強的人際對抗。"
        case "御宅文化":
            return "同人、收藏、興趣圈與次文化視角都會聚在這裡，想看更貼近宅文化日常的作品可以先看。"
        case "惡搞":
            return "玩既有作品、類型套路或角色印象的惡搞作品都在這裡，適合想看懂梗後更有趣的內容。"
        case "表演藝術":
            return "舞台、演技與表現者成長都收在這裡，適合找一部把練習與上場張力拍得很好的作品。"
        case "寵物":
            return "有動物陪伴、互動與日常感的作品都在這裡，適合想看輕鬆又溫暖的內容時慢慢挑。"
        case "心理":
            return "角色內在拉扯、認知壓力與情緒深度更強的作品都集中在這裡，適合想看後勁重一點的故事。"
        case "競速":
            return "速度感、技巧與勝負瞬間最重要的作品都在這裡，想先看能把腎上腺素拉高的類型可以看這區。"
        case "轉生":
            return "以重新開始的人生與新身份為主軸的作品都在這裡，適合找設定進入門檻低又有成長感的故事。"
        case "逆後宮":
            return "多位角色圍繞主角展開情感線的作品都在這裡，適合依角色魅力與互動節奏慢慢挑。"
        case "戀愛現狀":
            return "重點不在推進而在關係維持與微妙平衡的作品都在這裡，適合喜歡慢火細熬互動的人。"
        case "武士":
            return "刀光、信念與時代氣質兼具的作品都集中在這裡，適合先找一部帶有強烈風格的硬派故事。"
        case "校園":
            return "青春、社團、友情與成長最常在這區相遇，想找容易投入角色日常的作品可以先看這裡。"
        case "演藝圈":
            return "台前台後的壓力、競爭與發光時刻都在這裡，適合想看角色追夢與現實拉扯的作品。"
        case "太空":
            return "宇宙尺度、航行感與未知邊界帶來的魅力都收在這裡，適合找世界觀更開闊的作品。"
        case "策略遊戲":
            return "規則理解、佈局與腦力交鋒是這區主軸，想看角色靠思考取勝的故事可以先看這裡。"
        case "超能力":
            return "特殊能力與人物命運交織出的作品都集中在這裡，適合想看招式感和角色張力並存的故事。"
        case "生存":
            return "資源、壓力與活下去的選擇是這區主軸，想看節奏緊、壓迫感強的故事可以先看。"
        case "團隊運動":
            return "合作、默契與整體戰術更重要的作品都在這裡，適合喜歡群像成長與比賽節奏的人。"
        case "時間旅行":
            return "因果、選擇與時間回返帶來的張力都收在這裡，適合喜歡一層層拼回全貌的故事。"
        case "吸血鬼":
            return "夜色、危險氣質與非人魅力兼具的作品都在這裡，適合找一部氛圍感夠強的題材來看。"
        case "遊戲":
            return "無論是闖關、規則或虛擬世界延伸，跟遊戲有關的作品都集中在這裡，適合先找熟悉感高的題材。"
        case "視覺藝術":
            return "繪畫、創作與觀看方式本身成為主題的作品都在這裡，適合想找美感與表現欲並重的內容。"
        case "職場":
            return "工作節奏、人際分工與現實壓力交會的作品都收在這裡，適合想看更貼近人生階段的故事。"
        case "都市奇幻":
            return "把奇幻元素放進現代城市日常的作品都在這裡，適合找熟悉背景裡長出異常魅力的故事。"
        case "惡役千金":
            return "帶有改命、反轉與角色自覺趣味的作品都集中在這裡，適合喜歡設定感鮮明的人先挑。"
        case "女性向":
            return "更貼近成熟女性情感與人生視角的作品都在這裡，適合想找關係描寫細膩一點的故事。"
        case "兒童向":
            return "節奏清楚、內容親近且容易投入的作品都收在這裡，適合先找一部輕鬆好進入的作品。"
        case "青年向":
            return "題材、節奏與情緒表現更偏成熟的作品都在這裡，適合想看密度更高一些的故事。"
        case "少女向":
            return "角色魅力、戀愛氛圍與青春情緒兼具的作品都在這裡，適合先找最打動你的心動節奏。"
        case "少年向":
            return "成長、友情、對決與突破自我是這區主軸，想找王道感強、追起來很順的作品可以先看這裡。"
        default:
            return "\(genreTitle) 類作品會集中在這裡，方便你依照喜歡的風格、節奏與題材慢慢往下完整探索。"
        }
    }
}
