import {readFile,rename,writeFile} from "node:fs/promises";
import {resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {buildDarksideSnapshot,diffDarksideSnapshots,discoverDarksideRuntime,renderDarksideSnapshot,type DarksideSnapshot} from "./darksideRefresh.js";

export type DarksideFetcher=(url:string,init?:RequestInit)=>Promise<Response>;
const pageUrl="https://darkside-world.com/products/brand/darkside",catalogUrl="https://darkside-world.com/products/catalog",output=resolve("seeds/darkside-generated.ts");
const userAgent="HookahBoss-CatalogRefresh/1.0 (+official-source-audit; no-cookies)";
async function get(fetcher:DarksideFetcher,url:string,headers:HeadersInit={}):Promise<Response>{let last:unknown;for(let attempt=0;attempt<3;attempt++){try{const response=await fetcher(url,{redirect:"follow",signal:AbortSignal.timeout(12_000),headers:{accept:"text/html,application/json","user-agent":userAgent,...headers}});if(response.ok)return response;if(![408,425,429,500,502,503,504].includes(response.status))throw new Error(`DARKSIDE source HTTP ${response.status}`);last=new Error(`DARKSIDE source HTTP ${response.status}`)}catch(error){last=error}}throw last}

export async function loadDarksidePages(fetcher:DarksideFetcher=fetch){
  const html=await(await get(fetcher,pageUrl)).text();
  const bundlePaths=[...new Set([...html.matchAll(/(?:src|href)="(\/products\/_nuxt\/[^"]+\.js)"/g)].map(match=>match[1]!))];
  if(!bundlePaths.length) throw new Error("No DARKSIDE Nuxt bundles discovered");
  const bundles=await Promise.all(bundlePaths.map(async path=>await(await get(fetcher,new URL(path,pageUrl).href)).text()));
  const runtime=discoverDarksideRuntime(html,bundles),apiUrl=`${runtime.apiBase.replace(/\/+$/,'')}/ext_api/v1/flavors`,pages:unknown[]=[];
  let page=1,totalPages=1,totalDocs:number|undefined;
  do {
    const envelope=await(await get(fetcher,`${apiUrl}?page=${page}&brand=${runtime.brandId}`,{"x-access-token":runtime.accessToken})).json() as {data?:{page?:unknown;totalPages?:unknown;totalDocs?:unknown;docs?:unknown[]}};
    const data=envelope.data;
    if(!data||data.page!==page||!Number.isInteger(data.totalPages)||!Number.isInteger(data.totalDocs)||!Array.isArray(data.docs)) throw new Error("Invalid DARKSIDE API page");
    if(totalDocs!==undefined&&totalDocs!==data.totalDocs) throw new Error("DARKSIDE total changed during pagination");
    totalDocs=Number(data.totalDocs); totalPages=Number(data.totalPages); pages.push(data); page++;
    if(page>101) throw new Error("DARKSIDE pagination exceeded safety bound");
  } while(page<=totalPages);
  return {runtime,apiUrl,pages};
}

export async function runDarksideRefresh(args=process.argv.slice(2),fetcher:DarksideFetcher=fetch){
  const check=args.includes("--check"),dryRun=args.includes("--dry-run"),loaded=await loadDarksidePages(fetcher),today=new Date().toISOString().slice(0,10);
  const snapshot=buildDarksideSnapshot(loaded.pages as never,{pageUrl,catalogUrl,apiUrl:loaded.apiUrl,brandId:loaded.runtime.brandId,accessedAt:today,verifiedAt:today,publisher:"DARKSIDE"});
  let before:DarksideSnapshot|undefined,existing="";try{existing=await readFile(output,"utf8");before=(await import(`${pathToFileURL(output).href}?t=${Date.now()}`)).darksideSnapshot}catch{}
  const rendered=renderDarksideSnapshot(snapshot),diff=diffDarksideSnapshots(before,snapshot);console.log(JSON.stringify({...diff,total:snapshot.products.length,mode:check?"check":dryRun?"dry-run":"write"},null,2));
  if(check){if(existing!==rendered)process.exitCode=1}else if(!dryRun){const temporary=`${output}.tmp`;await writeFile(temporary,rendered,"utf8");await rename(temporary,output)}
}
if(process.argv[1]&&import.meta.url===new URL(`file://${process.argv[1]}`).href)await runDarksideRefresh();
