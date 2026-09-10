import {readFile,rename,writeFile} from "node:fs/promises";
import {resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {buildBlackburnSnapshot,diffBlackburnSnapshots,discoverBlackburnStore,renderBlackburnSnapshot,type BlackburnSnapshot} from "./blackburnRefresh.js";

export type Fetcher=(url:string,init?:RequestInit)=>Promise<Response>;
const pageUrl="https://www.blckburn.com/taste",output=resolve("seeds/blackburn-generated.ts");
const userAgent="HookahBoss-CatalogRefresh/1.0 (+official-source-audit; no-cookies)";

async function get(fetcher:Fetcher,url:string):Promise<Response>{let last:unknown;for(let attempt=0;attempt<=2;attempt++){try{const response=await fetcher(url,{redirect:"follow",signal:AbortSignal.timeout(12_000),headers:{"user-agent":userAgent,"accept":"text/html,application/json"}});if(response.ok)return response;if(![408,425,429,500,502,503,504].includes(response.status))throw new Error(`BlackBurn source HTTP ${response.status}`);last=new Error(`BlackBurn source HTTP ${response.status}`)}catch(error){last=error}}throw last}

export async function loadBlackburnPages(fetcher:Fetcher=fetch){const ids=discoverBlackburnStore(await(await get(fetcher,pageUrl)).text()),apiUrl=`https://store.tildaapi.com/api/getproductslist/?storepartuid=${ids.storepartuid}&recid=${ids.recid}`,pages:unknown[]=[];let slice=1,total=Infinity,received=0;while(received<total){const page=await(await get(fetcher,`${apiUrl}&slice=${slice}&size=36`)).json() as {total?:unknown;products?:unknown[];nextslice?:unknown};if(!Number.isInteger(page.total)||!Array.isArray(page.products))throw new Error("Invalid BlackBurn API page");total=Number(page.total);pages.push(page);received+=page.products.length;if(received>=total)break;const next=Number(page.nextslice);if(!Number.isInteger(next)||next<=slice)throw new Error("BlackBurn pagination stopped before declared total");slice=next;if(pages.length>100)throw new Error("BlackBurn pagination exceeded safety bound")}return{ids,apiUrl,pages}}

export async function runBlackburnRefresh(args=process.argv.slice(2),fetcher:Fetcher=fetch){const check=args.includes("--check"),dryRun=args.includes("--dry-run"),loaded=await loadBlackburnPages(fetcher),today=new Date().toISOString().slice(0,10),snapshot=buildBlackburnSnapshot(loaded.pages as never,{pageUrl,apiUrl:loaded.apiUrl,recid:loaded.ids.recid,storepartuid:loaded.ids.storepartuid,accessedAt:today,verifiedAt:today,publisher:"BlackBurn"});let before:BlackburnSnapshot|undefined,existing="";try{existing=await readFile(output,"utf8");before=(await import(`${pathToFileURL(output).href}?t=${Date.now()}`)).blackburnSnapshot}catch{}const rendered=renderBlackburnSnapshot(snapshot),diff=diffBlackburnSnapshots(before,snapshot);console.log(JSON.stringify({...diff,total:snapshot.products.length,mode:check?"check":dryRun?"dry-run":"write"},null,2));if(check){if(existing!==rendered)process.exitCode=1}else if(!dryRun){const temporary=`${output}.tmp`;await writeFile(temporary,rendered,"utf8");await rename(temporary,output)}}

if(process.argv[1]&&import.meta.url===new URL(`file://${process.argv[1]}`).href)await runBlackburnRefresh();
