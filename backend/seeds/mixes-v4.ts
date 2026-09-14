import type { CatalogSource } from "./catalog-v1.js";
import type { MixComponentSeed, OfficialMixSeed } from "./mixes-v1.js";

const source = (id: string, title: string, author: string): CatalogSource => ({
  key: `musthave-mix-v4-${id}`,
  url: `https://musthave.ru/showmixes/view/${id}/`,
  title,
  publisher: "MUSTHAVE",
  sourceType: "user_recipe",
  author,
  percentageEvidence: "explicit_numeric_percentages",
  accessedAt: "2026-09-13",
  verifiedAt: "2026-09-13",
  confidence: "high",
  notes: "Publicly attributed recipe hosted on the official MUSTHAVE platform; every component has an explicit numeric percentage. Commerce fields ignored."
});

export const mixSourcesV4: CatalogSource[] = [
  source("489", "Микс для неё #489", "Александр Томм"),
  source("514", "Дорога в лето #514", "Christopher Alesund"),
  source("1175", "Потрясающий микс", "Aslan Abdrasil"),
  source("649", "Чаепитие #649", "Алик Курбанов"),
  source("600", "Микс #600", "Антон Бодров"),
  source("1380", "Лимонное мороженое", "Екатерина Крупина"),
  source("1055", "Арбузная ванилька", "Валерия Миллер"),
  source("519", "Завтрак в тайланде #519", "Сергей Алексеевич"),
  source("29", "Пушка", "Виктор Ибрагимов"),
  source("1322", "ПЕЙТЕ ВОДУ ИЗ БАЙКАЛА", "Роман Старченков"),
  source("1191", "НАПИТОЧНЫЙ ЧАЙ БАЙКАЛ", "Jack Daniels"),
  source("1427", "Ромовый какао с бузиной", "Денис Кривопалов"),
  source("1371", "Мятно-фруктовая выпечка", "Павел Гладких"),
  source("1217", "Silent pie", "Инна Кукина")
];

const c = (slug: string, percentage: number): MixComponentSeed => ({
  product: `musthave/original/${slug}`,
  percentage
});

const m = (
  id: string,
  slug: string,
  titleRu: string,
  titleEn: string,
  summaryRu: string,
  summaryEn: string,
  components: MixComponentSeed[]
): OfficialMixSeed => ({
  slug,
  titleRu,
  titleEn,
  summaryRu,
  summaryEn,
  translationOrigin: "normalized_translation",
  sourceKey: `musthave-mix-v4-${id}`,
  components
});

export const officialMixesV4: OfficialMixSeed[] = [
  m(
    "489",
    "pineapple-mango-coconut",
    "Ананас, манго и кокос",
    "Pineapple Mango Coconut",
    "Тропический ананас и манго со сливочным кокосовым завершением.",
    "Tropical pineapple and mango with a creamy coconut finish.",
    [c("pineapple-rings", 50), c("mango-sling", 30), c("coconut-shake", 20)]
  ),
  m(
    "514",
    "summer-raspberry-mango",
    "Дорога в лето",
    "Road to Summer",
    "Малина, яблочные леденцы и манго с прохладной мятой.",
    "Raspberry, apple candy, and mango with cooling mint.",
    [c("raspberry", 40), c("apple-drops", 30), c("mango-sling", 20), c("ice-mint", 10)]
  ),
  m(
    "1175",
    "cool-banana-forest-berries",
    "Прохладный банан с ягодами",
    "Cool Banana Forest Berries",
    "Барбарисовые конфеты и банан с лесными ягодами и выраженным охлаждением.",
    "Barberry candy and banana with forest berries and pronounced cooling.",
    [c("barberry-candy", 30), c("frosty", 30), c("banana-mama", 20), c("forest-berries", 20)]
  ),
  m(
    "649",
    "lemon-caramel-choco-mint",
    "Лимонная карамель с шоколадной мятой",
    "Lemon Caramel Choco Mint",
    "Лимонный пирог со сливочной карамелью, ананасом и шоколадной мятой.",
    "Lemon pie with creamy caramel, pineapple, and chocolate mint.",
    [c("lemon-pie", 40), c("candy-cow", 30), c("pineapple-rings", 20), c("choco-mint", 10)]
  ),
  m(
    "600",
    "unicorn-choco-pistachio",
    "Кукурузное безе с шоколадной мятой",
    "Corn Meringue with Choco Mint",
    "Кукурузные палочки и безе с шоколадной мятой, печеньем, цитрусом и фисташковым пирогом.",
    "Corn puffs and meringue with chocolate mint, cookie, citrus, and pistachio cake.",
    [c("unicorn-treats", 50), c("choco-mint", 20), c("cookie", 10), c("lemon-lime", 10), c("pistachio-cake", 10)]
  ),
  m(
    "1380",
    "lemon-caramel-ice-cream",
    "Лимонное мороженое",
    "Lemon Ice Cream",
    "Сливочная карамель с яркой кислинкой лемонграсса.",
    "Creamy caramel with the bright tartness of lemongrass.",
    [c("candy-cow", 60), c("lemongrass", 40)]
  ),
  m(
    "1055",
    "watermelon-vanilla",
    "Арбузная ванилька",
    "Watermelon Vanilla",
    "Сочный арбуз со сладким ванильным кремом.",
    "Juicy watermelon with sweet vanilla cream.",
    [c("watermelon", 60), c("vanilla-cream", 40)]
  ),
  m(
    "519",
    "mango-rice-breakfast",
    "Завтрак в Таиланде",
    "Breakfast in Thailand",
    "Спелое манго с мягким вкусом молочной рисовой каши.",
    "Ripe mango with the mellow flavor of milky rice porridge.",
    [c("mango-sling", 60), c("milky-rice", 40)]
  ),
  m(
    "29",
    "tropical-pear-marula",
    "Тропический сок с грушей",
    "Tropical Juice with Pear",
    "Тропический сок с грушей и лёгким акцентом марулы.",
    "Tropical juice with pear and a light marula accent.",
    [c("tropic-juice", 60), c("mad-pear", 30), c("marula", 10)]
  ),
  m(
    "1322",
    "cranberry-baikal-elderberry",
    "Ягодный Байкал с бузиной",
    "Berry Baikal with Elderberry",
    "Клюква, лесные травы и бузина с эстрагоном и барбарисом.",
    "Cranberry, forest herbs, and elderberry with estragon and barberry.",
    [c("cranberry", 40), c("baikal", 20), c("elderberry", 20), c("estragon", 10), c("barberry-candy", 10)]
  ),
  m(
    "1191",
    "baikal-tea",
    "Напиточный чай «Байкал»",
    "Baikal Tea Drink",
    "Хвойно-травяной Байкал с красным и марокканским чаем и охлаждением.",
    "Herbal Baikal soda with red and Moroccan tea plus cooling.",
    [c("baikal", 40), c("red-tea", 30), c("morocco", 20), c("frosty", 10)]
  ),
  m(
    "1427",
    "rum-cacao-elderberry",
    "Ромовый какао с бузиной",
    "Rum Cacao with Elderberry",
    "Какао и маршмеллоу с терпкой бузиной и ромовой нотой.",
    "Cacao and marshmallow with tart elderberry and a rum note.",
    [c("cacao", 50), c("elderberry", 30), c("caribbean-rum", 20)]
  ),
  m(
    "1371",
    "minty-pecan-pastry",
    "Мятно-фруктовая выпечка",
    "Minty Fruit Pastry",
    "Шоколадная мята и кленовый пекан с охлаждением и фруктовой нотой.",
    "Chocolate mint and maple pecan with cooling and a fruit accent.",
    [c("choco-mint", 50), c("maple-pecan", 20), c("frosty", 20), c("pinkman", 10)]
  ),
  m(
    "1217",
    "apple-pecan-rum-pie",
    "Яблочный пирог с пеканом и ромом",
    "Apple Pecan Rum Pie",
    "Яблочная выпечка с кленовым пеканом и карибским ромом.",
    "Apple pastry with maple pecan and Caribbean rum.",
    [c("charlotte-pie", 50), c("maple-pecan", 30), c("caribbean-rum", 20)]
  )
];
