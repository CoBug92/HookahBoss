import type {CatalogSource} from "./catalog-v1.js";

export type ArticleCategory = "fundamentals" | "preparation" | "bowls_heat" | "care" | "safety";
export interface Section {heading: string; body: string}
export interface ArticleSeed {
  slug: string; category: ArticleCategory; titleRu: string; titleEn: string;
  summaryRu: string; summaryEn: string; bodyRu: Section[]; bodyEn: Section[];
  readingMinutes: number; related: string[]; sourceKeys: string[];
}

const source = (key: string, url: string, title: string, publisher: string): CatalogSource => ({
  key, url, title, publisher, accessedAt: "2026-09-09", verifiedAt: "2026-09-09",
  confidence: "high", notes: "Editorial synthesis source; no passage is reproduced verbatim.",
});
export const articleSourcesV1 = [
  source("cdc-hookah", "https://www.cdc.gov/tobacco/other-tobacco-products/hookahs.html", "Hookahs", "CDC"),
  source("who-waterpipe", "https://www.who.int/publications-detail-redirect/fact-sheet-waterpipe-tobacco-smoking-and-health", "Waterpipe tobacco smoking and health", "World Health Organization"),
  source("nhs-shisha", "https://www.nhs.uk/live-well/quit-smoking/paan-bidi-and-shisha-risks/", "Paan, bidi and shisha", "NHS"),
  source("kaloud-faq", "https://kaloud.com/pages/faq", "Frequently Asked Questions", "Kaloud"),
  source("kaloud-instructions", "https://kaloud.com/pages/instructions", "Instructions", "Kaloud"),
  {...source("darkside-academy", "https://darkside-world.com/academy/wiki", "DARKSIDE Academy knowledge base", "DARKSIDE"), accessedAt: "2026-09-10", verifiedAt: "2026-09-10"},
];
const section = (heading: string, body: string): Section => ({heading, body});

export const articlesV1: ArticleSeed[] = [
  {
    slug: "hookah-components", category: "fundamentals",
    titleRu: "Анатомия хорошей тяги", titleEn: "Anatomy of a clean draw",
    summaryRu: "Разбираемся, где теряется герметичность и почему мелкие детали меняют ощущения.",
    summaryEn: "Find where airtightness is lost and why small parts change the whole session.",
    bodyRu: [
      section("Один воздушный тракт", "Чаша, шахта, колба, шланг и мундштук работают как единый путь воздуха. Даже небольшой зазор делает тягу пустой и заставляет сильнее затягиваться."),
      section("Проверка без дыма", "Соберите кальян без угля, закройте верх шахты ладонью и аккуратно потяните воздух через шланг. Сопротивление помогает найти неплотный уплотнитель или клапан до начала сессии."),
      section("Что обслуживать", "Промывайте совместимые детали, проверяйте шарик клапана и меняйте изношенные уплотнители. Вода охлаждает дым, но не удаляет все токсичные вещества и не делает курение безопасным."),
    ],
    bodyEn: [
      section("One air path", "The bowl, stem, base, hose, and mouthpiece form one connected air path. Even a small gap can make the draw feel empty and encourage harder pulls."),
      section("Test before smoke", "Assemble the hookah without charcoal, cover the top of the stem, and draw gently through the hose. Resistance can reveal a loose grommet or valve before the session starts."),
      section("Maintain small parts", "Rinse compatible parts, inspect the purge ball, and replace worn seals. Water cools smoke, but it does not remove all toxic substances or make smoking safe."),
    ],
    readingMinutes: 6, related: ["first-session-checklist", "routine-cleaning"], sourceKeys: ["cdc-hookah", "darkside-academy"],
  },
  {
    slug: "first-session-checklist", category: "fundamentals",
    titleRu: "Пять минут до первого угля", titleEn: "Five minutes before the first coal",
    summaryRu: "Проверка сборки, места и инвентаря до того, как исправлять ошибки станет сложно.",
    summaryEn: "Check the setup, space, and tools before mistakes become difficult to fix.",
    bodyRu: [
      section("Сначала устойчивость", "Поставьте колбу на ровную негорючую поверхность, проверьте соединения и убедитесь, что шланг не может потянуть конструкцию за собой."),
      section("Подготовьте всё сразу", "До нагрева положите рядом щипцы, безопасную подставку для угля и воду для питья. Горячий уголь не должен перемещаться через комнату в поисках инструмента."),
      section("Проветривание обязательно", "Обеспечьте постоянный приток свежего воздуха и не допускайте рядом детей и животных. Проветривание снижает накопление продуктов горения, но не делает дым безопасным."),
    ],
    bodyEn: [
      section("Start with stability", "Place the base on a level, nonflammable surface, check every connection, and make sure the hose cannot pull the setup over."),
      section("Prepare every tool", "Before heating, keep tongs, a safe charcoal tray, and drinking water within reach. Hot charcoal should never travel across the room while you search for equipment."),
      section("Ventilation is essential", "Maintain a continuous supply of fresh air and keep children and pets away. Ventilation reduces buildup from combustion, but it does not make smoke safe."),
    ],
    readingMinutes: 5, related: ["hookah-components", "charcoal-co-safety"], sourceKeys: ["kaloud-instructions", "cdc-hookah"],
  },
  {
    slug: "building-a-mix", category: "preparation",
    titleRu: "Как собрать микс с сюжетом", titleEn: "Build a mix with a story",
    summaryRu: "От первого впечатления до послевкусия — без случайного набора ароматов.",
    summaryEn: "Shape the first impression and finish without assembling a random flavor list.",
    bodyRu: [
      section("Придумайте направление", "Опишите будущий микс одной фразой: сочный цитрус, холодный лимонад или тёплый десерт. Это помогает отсеять вкусы, которые не поддерживают выбранную идею."),
      section("Распределите роли", "Основа должна считываться первой, поддержка добавляет объём, а акцент появляется коротко и не спорит с главной темой. Для первой версии достаточно трёх компонентов."),
      section("Редактируйте, а не пересобирайте", "Запишите продукты, доли и одно наблюдение. В следующей попытке меняйте только один компонент или его долю — так удачная версия становится повторяемой."),
    ],
    bodyEn: [
      section("Choose a direction", "Describe the intended mix in one phrase: juicy citrus, chilled lemonade, or warm dessert. This constraint filters out flavors that do not support the idea."),
      section("Assign clear roles", "The base should arrive first, support adds body, and an accent appears briefly without competing with the theme. Three components are enough for a first draft."),
      section("Edit instead of rebuilding", "Record the products, shares, and one observation. Change only one component or percentage next time so a good result becomes repeatable."),
    ],
    readingMinutes: 7, related: ["packing-consistency", "heat-signals"], sourceKeys: ["darkside-academy"],
  },
  {
    slug: "packing-consistency", category: "preparation",
    titleRu: "Повторяемость вместо случайной удачи", titleEn: "Consistency over accidental luck",
    summaryRu: "Как сравнивать укладки и понимать, какое изменение действительно сработало.",
    summaryEn: "Compare packing methods and learn which change actually improved the result.",
    bodyRu: [
      section("Создайте контрольную точку", "Возьмите одну чашу, одинаковую массу смеси и привычный способ распределения. Не перекрывайте отверстия и фиксируйте уровень относительно края чаши."),
      section("Разделяйте переменные", "Плотность, отступ, количество угля и режим устройства контроля жара влияют одновременно. Меняйте только один параметр, иначе причина результата останется неясной."),
      section("Ведите короткий журнал", "Достаточно фотографии, пропорций и трёх оценок: старт, стабильность вкуса и момент появления резкости. Несколько записей быстро покажут закономерность."),
    ],
    bodyEn: [
      section("Create a baseline", "Use one bowl, the same mixture mass, and a familiar distribution method. Keep openings clear and record the gap below the rim."),
      section("Separate variables", "Density, rim gap, charcoal count, and heat-device settings all interact. Change only one parameter or the result cannot explain its own cause."),
      section("Keep a short log", "A photo, exact percentages, and three notes are enough: startup, flavor stability, and the first sign of harshness. Patterns appear after only a few records."),
    ],
    readingMinutes: 6, related: ["building-a-mix", "choosing-bowl"], sourceKeys: ["kaloud-faq", "darkside-academy"],
  },
  {
    slug: "choosing-bowl", category: "bowls_heat",
    titleRu: "Как чаша меняет сценарий жара", titleEn: "How a bowl changes heat behavior",
    summaryRu: "Форма, материал и посадка устройства работают как единая система.",
    summaryEn: "Shape, material, and device fit behave as one connected system.",
    bodyRu: [
      section("Смотрите не только на форму", "Материал и толщина стенок определяют, насколько быстро чаша реагирует на изменение жара. Форма влияет на смесь, но не работает отдельно от укладки."),
      section("Проверяйте совместимость", "Устройство контроля жара должно стоять устойчиво и не опираться на смесь. Неправильная посадка создаёт непредсказуемый контакт и мешает повторить результат."),
      section("Выбирайте под задачу", "Для сравнения миксов полезнее знакомая предсказуемая чаша, чем новая эффектная форма. Сначала освойте один комплект, затем сравнивайте альтернативы."),
    ],
    bodyEn: [
      section("Look beyond shape", "Material and wall thickness influence how quickly a bowl reacts to heat changes. Shape affects distribution, but it cannot be separated from the pack."),
      section("Check compatibility", "A heat-management device must sit securely without resting on the mixture. A poor fit creates inconsistent contact and prevents repeatable results."),
      section("Choose for the task", "A familiar, predictable bowl is better for comparing mixes than an unfamiliar dramatic shape. Learn one setup first, then compare alternatives."),
    ],
    readingMinutes: 6, related: ["heat-signals", "packing-consistency"], sourceKeys: ["kaloud-faq", "kaloud-instructions"],
  },
  {
    slug: "heat-signals", category: "bowls_heat",
    titleRu: "Жар без горечи: читаем чашу", titleEn: "Read the bowl before it turns harsh",
    summaryRu: "Отличаем прогрев от перегрева и меняем только то, что действительно мешает вкусу.",
    summaryEn: "Tell warm-up from overheating and change only what is hurting the flavor.",
    bodyRu: [
      section("Дайте системе время", "Слабый вкус в первую минуту не обязательно требует нового угля. Чаше и устройству нужно прогреться; слишком ранняя коррекция часто вызывает резкий скачок температуры."),
      section("Читайте последовательность", "Резкость, быстро исчезающий аромат и неприятное ощущение в горле могут указывать на избыток жара. Оценивайте признак вместе с тем, как быстро он появился."),
      section("Корректируйте небольшим шагом", "Снимите один уголь или откройте вентиляцию устройства, затем подождите. Не меняйте одновременно положение угля, тягу и укладку."),
    ],
    bodyEn: [
      section("Give the system time", "Weak flavor in the first minute does not automatically call for more charcoal. The bowl and device need to warm; an early correction often causes a temperature jump."),
      section("Read a sequence", "Harshness, rapidly fading aroma, and throat irritation can indicate excess heat. Interpret each sign together with how quickly it appeared."),
      section("Correct in small steps", "Remove one coal or open the device vents, then wait. Do not change coal position, draw, and pack at once or the result will teach you nothing."),
    ],
    readingMinutes: 6, related: ["choosing-bowl", "charcoal-co-safety"], sourceKeys: ["kaloud-faq", "kaloud-instructions"],
  },
  {
    slug: "routine-cleaning", category: "care",
    titleRu: "Чистый вкус начинается после сессии", titleEn: "Clean flavor starts after the session",
    summaryRu: "Короткий ритуал ухода, который не даёт старым ароматам испортить следующий микс.",
    summaryEn: "A short care routine that keeps old aromas out of the next mix.",
    bodyRu: [
      section("Дождитесь остывания", "Не разбирайте горячую чашу или устройство контроля жара. Когда детали остынут, удалите смесь и уголь, не оставляя сироп засыхать на поверхности."),
      section("Промойте воздушный тракт", "Тёплой водой промойте совместимые детали, уделяя внимание шахте, колбе и моющемуся шлангу. Для конкретных покрытий следуйте инструкции производителя."),
      section("Сушите раздельно", "Оставьте детали разобранными до полного высыхания. Остаточная влага и сироп удерживают запахи, ухудшают тягу и сокращают срок службы уплотнителей."),
    ],
    bodyEn: [
      section("Wait until cool", "Do not disassemble a hot bowl or heat device. Once everything has cooled, remove the mixture and charcoal before syrup dries onto surfaces."),
      section("Rinse the air path", "Use warm water on compatible parts, paying attention to the stem, base, and washable hose. Follow manufacturer guidance for specific finishes."),
      section("Dry in separate pieces", "Leave parts disassembled until fully dry. Residual moisture and syrup retain odors, affect draw, and shorten seal life."),
    ],
    readingMinutes: 5, related: ["deep-cleaning", "hookah-components"], sourceKeys: ["kaloud-instructions"],
  },
  {
    slug: "deep-cleaning", category: "care",
    titleRu: "Глубокая очистка без испорченного покрытия", titleEn: "Deep cleaning without damaged finishes",
    summaryRu: "Что делать, когда ополаскивания мало, а агрессивное средство использовать рискованно.",
    summaryEn: "What to do when rinsing is not enough and harsh cleaners are risky.",
    bodyRu: [
      section("Найдите источник запаха", "Проверьте по очереди колбу, шахту, клапан, шланг и уплотнители. Локальная диагностика помогает не замачивать без необходимости чувствительные детали."),
      section("Сверьтесь с материалом", "Стекло, силикон, металл и декоративные покрытия требуют разных средств. Не используйте абразивы или агрессивную химию без разрешения производителя."),
      section("Работайте мягко", "После остывания предпочтите замачивание разрешённых деталей и мягкую губку металлическому соскабливанию. Затем тщательно ополосните и полностью высушите комплект."),
    ],
    bodyEn: [
      section("Locate the source", "Inspect the base, stem, valve, hose, and seals one at a time. Local diagnosis avoids soaking finish-sensitive parts that do not need it."),
      section("Match the material", "Glass, silicone, metal, and decorative finishes require different products. Avoid abrasives or harsh chemicals unless the manufacturer allows them."),
      section("Use patience, not force", "After cooling, prefer approved soaking and a soft sponge over metal scraping. Rinse thoroughly and let the entire setup dry before assembly."),
    ],
    readingMinutes: 5, related: ["routine-cleaning", "choosing-bowl"], sourceKeys: ["kaloud-faq", "kaloud-instructions"],
  },
  {
    slug: "water-does-not-make-safe", category: "safety",
    titleRu: "Что вода меняет — и чего не меняет", titleEn: "What water changes — and what it does not",
    summaryRu: "Прохладный дым может ощущаться мягче, но это ощущение не измеряет риск.",
    summaryEn: "Cooler smoke can feel smoother, but that sensation does not measure risk.",
    bodyRu: [
      section("Ощущение не равно составу", "Вода охлаждает дым и меняет субъективное ощущение при вдыхании. Мягкость не означает, что вредные вещества исчезли или воздействие стало безопасным."),
      section("Что остаётся в дыме", "CDC и WHO указывают, что кальянный дым может содержать угарный газ, никотин, металлы и канцерогенные вещества из смеси и горящего угля."),
      section("Практический вывод", "Кальян нельзя считать безопасной альтернативой сигаретам. Вода, аксессуар или безтабачная смесь не дают оснований обещать безопасное использование."),
    ],
    bodyEn: [
      section("Sensation is not composition", "Water cools smoke and changes how inhalation feels. A smoother sensation does not mean harmful substances disappeared or exposure became safe."),
      section("What remains in smoke", "CDC and WHO state that hookah smoke can contain carbon monoxide, nicotine, metals, and carcinogenic substances from the mixture and burning charcoal."),
      section("The practical conclusion", "Hookah should not be treated as a safe alternative to cigarettes. Water, accessories, or tobacco-free mixtures do not justify claims of safe use."),
    ],
    readingMinutes: 6, related: ["charcoal-co-safety", "first-session-checklist"], sourceKeys: ["cdc-hookah", "who-waterpipe", "nhs-shisha"],
  },
  {
    slug: "charcoal-co-safety", category: "safety",
    titleRu: "Уголь и угарный газ: без мифов", titleEn: "Charcoal and carbon monoxide, without myths",
    summaryRu: "Почему проветривание важно, но открытое окно не превращает дым в безопасный.",
    summaryEn: "Why ventilation matters, but an open window cannot make smoke safe.",
    bodyRu: [
      section("Уголь — отдельный источник", "Горящий уголь добавляет к дыму угарный газ и другие токсичные вещества. Поэтому риск определяется не только составом смеси в чаше."),
      section("Проветривание не равно безопасности", "Постоянный приток свежего воздуха важен, однако не устраняет воздействие дыма. Окружающие также подвергаются вторичному дыму, а никотин вызывает зависимость."),
      section("Когда прекращать воздействие", "При головной боли, тошноте, слабости или спутанности прекратите воздействие, выйдите на свежий воздух и обратитесь за срочной медицинской помощью."),
    ],
    bodyEn: [
      section("Charcoal is a separate source", "Burning charcoal adds carbon monoxide and other toxic substances to smoke. Risk is therefore not determined only by the mixture inside the bowl."),
      section("Ventilation is not safety", "A continuous fresh-air supply matters, but it does not eliminate smoke exposure. Bystanders face secondhand smoke, and nicotine can cause dependence."),
      section("When to stop exposure", "If headache, nausea, weakness, or confusion occurs, stop exposure, move to fresh air, and seek urgent medical help."),
    ],
    readingMinutes: 6, related: ["water-does-not-make-safe", "first-session-checklist"], sourceKeys: ["cdc-hookah", "who-waterpipe", "nhs-shisha"],
  },
];
