import type { Intensity } from "../seeds/catalog-v1.js";

export type DarksideProduct = {
  uid: string;
  slug: string;
  title: string;
  descriptionRu: string;
  officialTags: string[];
  officialCategories: string[];
  tags: string[];
  strength: "medium";
  sweetness: Intensity;
  acidity: Intensity;
  freshness: Intensity;
};
export type DarksideSnapshot = {
  source: { pageUrl: string; catalogUrl: string; apiUrl: string; brandId: string; accessedAt: string; verifiedAt: string; publisher: "DARKSIDE" };
  products: DarksideProduct[];
};
type RawProduct = { id?: unknown; title?: unknown; friendlyUrl?: unknown; description?: unknown; brand?: { id?: unknown; title?: unknown }; tags?: unknown; categories?: unknown; strength?: unknown };
type RawPage = { docs?: unknown; totalDocs?: unknown; page?: unknown; totalPages?: unknown; hasNextPage?: unknown; nextPage?: unknown };

const mappings: Record<string, string[]> = {
  алкоголь:["alcohol"], ананас:["pineapple"], апельсин:["orange"], апельсиновый_сок:["orange","beverage"], арбуз:["watermelon"], базилик:["basil"], банан:["banana"], барбарисовые_леденцы:["candy"], белый_виноград:["grape"], бергамот:["bergamot"], бузина:["elderberry"], ваниль:["vanilla"], вафли:["waffle"], виноград:["grape"], виски:["whiskey"], вишневые_леденцы:["cherry","candy"], вишневый_блейзер:["cherry","beverage"], вишня:["cherry"], гранат:["pomegranate"], грейпфрут:["grapefruit"], груша:["pear"], гуава:["guava"], десертный:["pastry"], дыня:["melon"], ежевика:["blackberry"], жасмин:["jasmine"], жвачка:["bubblegum"], зеленое_яблоко:["apple"], зеленый_чай:["tea"], земляника:["strawberry"], кактус:["cactus"], кашмир:["spices"], киви:["kiwi"], кислый:["sour"], клубника:["strawberry"], клубничный_джем:["strawberry","jam"], клюква:["cranberry"], клюквенный_морс:["cranberry","beverage"], кокос:["coconut"], кола:["cola"], кофе:["coffee"], красная_смородина:["redcurrant"], красное_яблоко:["apple"], красный_апельсин:["orange"], красный_чай:["tea"], "крем-сода":["cream-soda"], крыжовник:["gooseberry"], лайм:["lime"], лесные_ягоды:["berry"], ликер:["liqueur"], лимон:["lemon"], лимонад:["lemonade"], малина:["raspberry"], манго:["mango"], маракуйя:["passion-fruit"], мед:["honey"], ментол:["cooling"], мороженое:["ice-cream"], мята:["mint"], напиток:["beverage"], овсяная_каша:["oatmeal"], освежающий:["cooling"], перечная_мята:["mint"], персик:["peach"], печенье:["cookie"], помело:["pomelo"], пряный:["spices"], свежий:["cooling"], сгущенное_молоко:["condensed-milk"], сирень:["lilac"], сладкий:["sweet"], сливки:["cream"], смузи:["smoothie"], травянистый:["herbal"], тропические_фрукты:["tropical-fruit"], фейхоа:["feijoa"], фруктовый:["fruit"], хвоя:["fir"], цитрус:["citrus"], цитрусовый:["citrus"], чай:["tea"], черная_смородина:["blackcurrant"], черника:["blueberry"], шалфей:["sage"], шоколад:["cacao"], энергетик:["energy-drink"], ягода:["berry"], ягодный:["berry"], ягоды:["berry"]
};
const nonFlavorTags = new Set(["лимитка"]);
const legacySlugs: Record<string,string> = { "KALEE GRAPEFRUIT 2.0": "kalee-grapefruit-2" };

export function discoverDarksideRuntime(html: string, bundles: string[]): { apiBase: string; accessToken: string; brandId: string } {
  const unique = (values: string[]) => [...new Set(values)];
  const apiBases = unique([...html.matchAll(/apiServer:"([^"]+)"/g)].map(match => match[1]!));
  const tokens = unique([...html.matchAll(/apiAccessToken:"([^"]+)"/g)].map(match => match[1]!));
  const brandIds = unique(bundles.flatMap(bundle => [...bundle.matchAll(/label:"DARKSIDE",value:"([a-f0-9]{24})"/g)].map(match => match[1]!)));
  if (apiBases.length !== 1 || tokens.length !== 1 || brandIds.length !== 1) throw new Error("Expected one official DARKSIDE runtime configuration");
  return { apiBase: apiBases[0]!, accessToken: tokens[0]!, brandId: brandIds[0]! };
}

export function normalizeDarksideTags(sourceTags: string[]): string[] {
  return [...new Set(sourceTags.flatMap(tag => mappings[tag] ?? []))];
}

export function buildDarksideSnapshot(pages: RawPage[], source: DarksideSnapshot["source"]): DarksideSnapshot {
  const totals = [...new Set(pages.map(page => page.totalDocs))];
  const pageNumbers = pages.map(page => page.page);
  if (totals.length !== 1 || !Number.isInteger(totals[0]) || pageNumbers.some((page,index) => page !== index + 1)) throw new Error("Invalid or inconsistent DARKSIDE pagination");
  const raw = pages.flatMap(page => Array.isArray(page.docs) ? page.docs as RawProduct[] : []);
  if (raw.length !== Number(totals[0])) throw new Error(`Expected ${totals[0]} DARKSIDE products, received ${raw.length}`);
  const ids = new Set<string>(), slugs = new Set<string>(), unclassified: string[] = [];
  const products = raw.map(item => {
    const uid=String(item.id??"").trim(), title=String(item.title??"").trim(), officialSlug=String(item.friendlyUrl??"").trim(), descriptionRu=String(item.description??"").trim();
    const officialTags=Array.isArray(item.tags)?item.tags.map(String):[], officialCategories=Array.isArray(item.categories)?item.categories.map(String):[];
    const slug=legacySlugs[title]??officialSlug;
    if(!uid||!title||!slug||!descriptionRu||item.brand?.id!==source.brandId||item.brand?.title!=="DARKSIDE"||item.strength!==2) throw new Error(`Invalid DARKSIDE product ${uid||title}`);
    if(ids.has(uid)||slugs.has(slug)) throw new Error(`Duplicate DARKSIDE product ${uid}/${slug}`); ids.add(uid); slugs.add(slug);
    const unknown=officialTags.filter(tag=>!mappings[tag]&&!nonFlavorTags.has(tag)); if(unknown.length) throw new Error(`Unknown official DARKSIDE tags: ${unknown.join(", ")}`);
    const tags=normalizeDarksideTags(officialTags); if(!tags.length) unclassified.push(title);
    const joined=officialTags.join(" ");
    return {uid,slug,title,descriptionRu,officialTags,officialCategories,tags,strength:"medium",sweetness:/сладкий/.test(joined)?"pronounced":"subtle",acidity:/кислый/.test(joined)?"pronounced":"subtle",freshness:/ментол|освежающий|свежий|мята/.test(joined)?"pronounced":"subtle"} satisfies DarksideProduct;
  });
  if(unclassified.length) throw new Error(`Unclassified DARKSIDE products: ${unclassified.join(", ")}`);
  return {source,products:products.sort((left,right)=>left.title.localeCompare(right.title,"en"))};
}

export function renderDarksideSnapshot(snapshot: DarksideSnapshot): string {
  return `// Generated by npm run catalog:refresh:darkside. Commerce, availability and media fields intentionally excluded.\nimport type { DarksideSnapshot } from "../src/darksideRefresh.js";\nexport const darksideSnapshot:DarksideSnapshot=${JSON.stringify(snapshot,null,2)};\n`;
}
export function diffDarksideSnapshots(before: DarksideSnapshot|undefined, after: DarksideSnapshot) {
  const previous=new Map((before?.products??[]).map(product=>[product.uid,product])), current=new Map(after.products.map(product=>[product.uid,product]));
  return {added:[...current.keys()].filter(id=>!previous.has(id)),changed:[...current].filter(([id,product])=>previous.has(id)&&JSON.stringify(previous.get(id))!==JSON.stringify(product)).map(([id])=>id),removed:[...previous.keys()].filter(id=>!current.has(id)),unclassified:[] as string[]};
}
