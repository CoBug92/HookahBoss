export type Strength = "light" | "medium" | "strong";
export type Intensity = "subtle" | "pronounced";
export type Confidence = "high" | "medium" | "low";
export type TranslationOrigin = "official" | "normalized_translation";

export interface CatalogSource {
  key: string;
  url: string;
  title: string;
  publisher: string;
  accessedAt: string;
  verifiedAt: string;
  confidence: Confidence;
  notes: string;
  sourceType?: "official_catalog" | "editorial_recipe" | "user_recipe" | "industry_catalog";
  author?: string;
  percentageEvidence?: "explicit_numeric_percentages";
}

export interface SeedProduct {
  slug: string;
  nameRu: string;
  nameEn: string;
  descriptionRu?: string;
  descriptionEn?: string;
  translationOrigin: TranslationOrigin;
  sourceKey: string;
  tags: string[];
  sweetness: Intensity;
  acidity: Intensity;
  freshness: Intensity;
}

export interface SeedLine {
  slug: string;
  name: string;
  strength: Strength;
  sourceKey: string;
  products: SeedProduct[];
}

export interface SeedBrand { slug: string; name: string; sourceKey: string; lines: SeedLine[] }

export const sources: CatalogSource[] = [
  { key: "musthave-catalog", url: "https://musthave.ru/category/tabak-dlya-kalyana/", title: "Табак для кальяна", publisher: "MUSTHAVE", accessedAt: "2026-09-09", verifiedAt: "2026-09-09", confidence: "high", notes: "Official current product catalog and product descriptions." },
  { key: "darkside-catalog", url: "https://darkside-world.com/products/catalog", title: "Каталог продуктов", publisher: "DARKSIDE", accessedAt: "2026-09-09", verifiedAt: "2026-09-09", confidence: "high", notes: "Official catalog; product names and flavor facets are available, but per-product strength is not exposed." },
  { key: "element-lines", url: "https://element-tobacco.ru/tobacco", title: "Линейки табака Element", publisher: "Element", accessedAt: "2026-09-09", verifiedAt: "2026-09-09", confidence: "high", notes: "Official source for Air, Water and Earth line strengths." },
  { key: "element-earth-catalog", url: "https://www.hookahportal.ru/tobaccos/element-zemlya", title: "Табаки — Element Земля", publisher: "Hookah Portal", accessedAt: "2026-09-09", verifiedAt: "2026-09-09", confidence: "medium", notes: "Industry catalog used because current product labels are image/JS-only on the official page; no prices were collected." }
];

const p = (slug: string, nameEn: string, nameRu: string, sourceKey: string, tags: string[], flags: Partial<Pick<SeedProduct, "sweetness" | "acidity" | "freshness">> = {}): SeedProduct => ({
  slug, nameEn, nameRu, sourceKey, tags,
  translationOrigin: "normalized_translation",
  sweetness: flags.sweetness ?? "pronounced",
  acidity: flags.acidity ?? "subtle",
  freshness: flags.freshness ?? "subtle"
});

export const brands: SeedBrand[] = [
  { slug: "musthave", name: "MUSTHAVE", sourceKey: "musthave-catalog", lines: [{ slug: "original", name: "Original", strength: "medium", sourceKey: "musthave-catalog", products: [
    p("space-flavour", "Space Flavour", "Космический вкус", "musthave-catalog", ["passion-fruit", "lychee", "candy"]),
    p("ice-cream", "Ice Cream", "Мороженое", "musthave-catalog", ["ice-cream", "vanilla"]),
    p("paradise", "Paradise", "Парадайз", "musthave-catalog", ["pineapple", "coconut", "cream"]),
    p("cacao", "Cacao", "Какао", "musthave-catalog", ["cacao"]),
    p("araram", "Araram", "Арарам", "musthave-catalog", ["grape", "berry", "mint"], { freshness: "pronounced" }),
    p("cinnamon-roll", "Cinnamon Roll", "Булочка с корицей", "musthave-catalog", ["pastry", "cinnamon"]),
    p("elderberry", "Elderberry", "Бузина", "musthave-catalog", ["elderberry"], { acidity: "pronounced" }),
    p("yolka", "Yolka", "Ёлка", "musthave-catalog", ["fir", "herbal"], { sweetness: "subtle", freshness: "pronounced" }),
    p("maple-pecan", "Maple Pecan", "Кленовый пекан", "musthave-catalog", ["maple", "pecan"]),
    p("cucunade", "Cucunade", "Кукунад", "musthave-catalog", ["cucumber", "lemonade"], { acidity: "pronounced", freshness: "pronounced" }),
    p("currant-orange-grape", "Currant Orange Grape", "Смородина, апельсин и виноград", "musthave-catalog", ["blackcurrant", "orange", "grape"], { acidity: "pronounced" }),
    p("candy-cow", "Candy Cow", "Кэнди Кау", "musthave-catalog", ["candy", "cream"]),
    p("berry-mors", "Berry Mors", "Ягодный морс", "musthave-catalog", ["berry", "beverage"], { acidity: "pronounced" }),
    p("lemongrass", "Lemongrass", "Лемонграсс", "musthave-catalog", ["lemongrass", "citrus"], { sweetness: "subtle", acidity: "pronounced", freshness: "pronounced" }),
    p("cherry-juice", "Cherry Juice", "Вишнёвый сок", "musthave-catalog", ["cherry", "beverage"], { acidity: "pronounced" })
  ]}]},
  { slug: "darkside", name: "DARKSIDE", sourceKey: "darkside-catalog", lines: [{ slug: "core", name: "Core", strength: "medium", sourceKey: "darkside-catalog", products: [
    p("admiral-acbar", "Admiral Acbar", "Адмирал Акбар", "darkside-catalog", ["oatmeal", "berry"]),
    p("bananapapa", "Bananapapa", "Бананапапа", "darkside-catalog", ["banana", "tropical-fruit"]),
    p("barvy-citrus", "Barvy Citrus", "Барви Цитрус", "darkside-catalog", ["orange", "grapefruit", "lemon"], { acidity: "pronounced" }),
    p("barvy-orange", "Barvy Orange", "Барви Апельсин", "darkside-catalog", ["orange", "beverage"], { acidity: "pronounced" }),
    p("basil-blast", "Basil Blast", "Базилик", "darkside-catalog", ["basil", "herbal"], { sweetness: "subtle" }),
    p("bassberry", "Bassberry", "Бузина", "darkside-catalog", ["elderberry"], { acidity: "pronounced" }),
    p("bergamonstr", "Bergamonstr", "Бергамонстр", "darkside-catalog", ["bergamot", "herbal"], { sweetness: "subtle", freshness: "pronounced" }),
    p("blackberry", "Blackberry", "Ежевика", "darkside-catalog", ["blackberry"], { acidity: "pronounced" }),
    p("blackcurrant", "Blackcurrant", "Чёрная смородина", "darkside-catalog", ["blackcurrant"], { acidity: "pronounced" }),
    p("blackout", "Blackout", "Блэкаут", "darkside-catalog", ["banana", "ice-cream"]),
    p("bloody-orange", "Bloody Orange", "Красный апельсин", "darkside-catalog", ["orange"], { acidity: "pronounced" }),
    p("blueberry-blast-2", "Blueberry Blast 2.0", "Черника 2.0", "darkside-catalog", ["blueberry"], { acidity: "pronounced" }),
    p("bounty-hunter", "Bounty Hunter", "Баунти Хантер", "darkside-catalog", ["coconut"]),
    p("breaking-red", "Breaking Red", "Брейкинг Ред", "darkside-catalog", ["pomegranate"], { acidity: "pronounced" }),
    p("cream-soda", "C.R.E.A.M.S.O.D.A.", "Крем-сода", "darkside-catalog", ["cream-soda", "vanilla", "beverage"])
  ]}]},
  { slug: "element", name: "Element", sourceKey: "element-lines", lines: [{ slug: "earth", name: "Earth", strength: "strong", sourceKey: "element-lines", products: [
    p("orange-tik-tak", "Orange Tik-Tak", "Апельсиновый тик-так", "element-earth-catalog", ["orange", "candy"]),
    p("maui", "Maui", "Ананас и папайя", "element-earth-catalog", ["pineapple", "papaya"], { acidity: "pronounced" }),
    p("elemint", "Elemint", "Мята", "element-earth-catalog", ["mint"], { sweetness: "subtle", freshness: "pronounced" }),
    p("feijoa-lemonade", "Feijoa Lemonade", "Лимонад из фейхоа", "element-earth-catalog", ["feijoa", "lemonade"], { acidity: "pronounced", freshness: "pronounced" }),
    p("mellow-blueberry", "Mellow Blueberry", "Спелая черника", "element-earth-catalog", ["blueberry"]),
    p("kashmir-feijoa", "Kashmir & Feijoa", "Кашмир и фейхоа", "element-earth-catalog", ["feijoa", "spices", "herbal"]),
    p("fruit-pulp", "Fruit Pulp", "Фруктовая мякоть", "element-earth-catalog", ["banana", "apple", "pineapple"]),
    p("grape-drink", "Grape Drink", "Виноградная газировка", "element-earth-catalog", ["grape", "beverage", "citrus"], { acidity: "pronounced" }),
    p("raspberry", "Raspberry", "Малина", "element-earth-catalog", ["raspberry"]),
    p("watermelon-holls", "Watermelon Holls", "Арбузный холс", "element-earth-catalog", ["watermelon", "mint"], { freshness: "pronounced" }),
    p("wild-jam", "Wild Jam", "Землянично-персиковый джем", "element-earth-catalog", ["strawberry", "peach"]),
    p("chak-chak", "Chak-Chak", "Чак-чак", "element-earth-catalog", ["honey", "pastry"]),
    p("cola", "Cola", "Кола", "element-earth-catalog", ["cola", "beverage"]),
    p("garnet-yoghurt", "Garnet Yoghurt", "Гранатовый йогурт", "element-earth-catalog", ["pomegranate", "yoghurt"], { acidity: "pronounced" }),
    p("siberry", "Siberry", "Сибирские ягоды", "element-earth-catalog", ["lingonberry", "cranberry", "blueberry"], { acidity: "pronounced" })
  ]}]}
];

export const tagProfiles: Record<string, "berry" | "fruit" | "citrus" | "dessert" | "beverage" | "herbal" | "spicy" | "fresh"> = {
  cooling:"fresh",
  "passion-fruit":"fruit",lychee:"fruit",candy:"dessert","ice-cream":"dessert",vanilla:"dessert",pineapple:"fruit",coconut:"fruit",cream:"dessert",cacao:"dessert",grape:"fruit",berry:"berry",mint:"herbal",pastry:"dessert",cinnamon:"spicy",elderberry:"berry",fir:"herbal",herbal:"herbal",maple:"dessert",pecan:"dessert",cucumber:"fruit",lemonade:"beverage",blackcurrant:"berry",orange:"citrus",beverage:"beverage",lemongrass:"herbal",citrus:"citrus",cherry:"berry",oatmeal:"dessert",banana:"fruit","tropical-fruit":"fruit",grapefruit:"citrus",lemon:"citrus",basil:"herbal",bergamot:"herbal",blackberry:"berry",blueberry:"berry",pomegranate:"fruit","cream-soda":"beverage",papaya:"fruit",feijoa:"fruit",spices:"spicy",apple:"fruit",raspberry:"berry",watermelon:"fruit",strawberry:"berry",peach:"fruit",honey:"dessert",cola:"beverage",yoghurt:"dessert",lingonberry:"berry",cranberry:"berry"
};

export const tagNames: Record<string, [string, string]> = {
  cooling:["Охлаждение","Cooling"],
  "passion-fruit":["Маракуйя","Passion fruit"],lychee:["Личи","Lychee"],candy:["Конфеты","Candy"],"ice-cream":["Мороженое","Ice cream"],vanilla:["Ваниль","Vanilla"],pineapple:["Ананас","Pineapple"],coconut:["Кокос","Coconut"],cream:["Сливки","Cream"],cacao:["Какао","Cacao"],grape:["Виноград","Grape"],berry:["Ягоды","Berries"],mint:["Мята","Mint"],pastry:["Выпечка","Pastry"],cinnamon:["Корица","Cinnamon"],elderberry:["Бузина","Elderberry"],fir:["Хвоя","Fir"],herbal:["Травы","Herbal"],maple:["Клён","Maple"],pecan:["Пекан","Pecan"],cucumber:["Огурец","Cucumber"],lemonade:["Лимонад","Lemonade"],blackcurrant:["Чёрная смородина","Blackcurrant"],orange:["Апельсин","Orange"],beverage:["Напиток","Beverage"],lemongrass:["Лемонграсс","Lemongrass"],citrus:["Цитрус","Citrus"],cherry:["Вишня","Cherry"],oatmeal:["Овсянка","Oatmeal"],banana:["Банан","Banana"],"tropical-fruit":["Тропические фрукты","Tropical fruit"],grapefruit:["Грейпфрут","Grapefruit"],lemon:["Лимон","Lemon"],basil:["Базилик","Basil"],bergamot:["Бергамот","Bergamot"],blackberry:["Ежевика","Blackberry"],blueberry:["Черника","Blueberry"],pomegranate:["Гранат","Pomegranate"],"cream-soda":["Крем-сода","Cream soda"],papaya:["Папайя","Papaya"],feijoa:["Фейхоа","Feijoa"],spices:["Специи","Spices"],apple:["Яблоко","Apple"],raspberry:["Малина","Raspberry"],watermelon:["Арбуз","Watermelon"],strawberry:["Земляника","Strawberry"],peach:["Персик","Peach"],honey:["Мёд","Honey"],cola:["Кола","Cola"],yoghurt:["Йогурт","Yoghurt"],lingonberry:["Брусника","Lingonberry"],cranberry:["Клюква","Cranberry"]
};
