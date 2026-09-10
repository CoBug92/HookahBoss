import assert from "node:assert/strict";
import pg from "pg";
import {inventoryMatchSQL} from "./app.js";

const url=process.env.DATABASE_URL;if(!url)throw new Error("DATABASE_URL is required");
const pool=new pg.Pool({connectionString:url,max:1}),db=await pool.connect();
const user="90000000-0000-4000-8000-000000000001",source="90000000-0000-4000-8000-000000000002";
const brand="90000000-0000-4000-8000-000000000003",line="90000000-0000-4000-8000-000000000004";
const tagA="90000000-0000-4000-8000-000000000005",tagB="90000000-0000-4000-8000-000000000006";
const products=[
 ["90000000-0000-4000-8000-000000000010","exact","Exact",tagA],
 ["90000000-0000-4000-8000-000000000011","sub-source","Sub source",tagA],
 ["90000000-0000-4000-8000-000000000012","sub-available","Sub available",tagA],
 ["90000000-0000-4000-8000-000000000013","missing","Missing",tagB],
 ["90000000-0000-4000-8000-000000000014","private-target","Private exact",tagB],
 ["90000000-0000-4000-8000-000000000015","denied","Denied",tagA]
] as const;
const mixIds=["90000000-0000-4000-8000-000000000111","90000000-0000-4000-8000-000000000112","90000000-0000-4000-8000-000000000113","90000000-0000-4000-8000-000000000114","90000000-0000-4000-8000-000000000115"];
try{
 await db.query("BEGIN");
 if(!(await db.query("SELECT 1 FROM schema_migrations WHERE version='009_fresh_flavor_profile.sql'")).rowCount)throw new Error("Migration 009 is required");
 await db.query("INSERT INTO content_sources(id,url,title,publisher,checked_at) VALUES($1,'https://fixture.invalid/inventory-matching','Fixture','HookahBoss','2026-09-10')",[source]);
 await db.query("INSERT INTO app_users(id,apple_subject) VALUES($1,'integration-inventory-user')",[user]);
 await db.query("INSERT INTO brands(id,slug,name,status,source_id,verified_at) VALUES($1,'integration-inventory-brand','Fixture','published',$2,'2026-09-10')",[brand,source]);
 await db.query("INSERT INTO tobacco_lines(id,brand_id,slug,name,strength,status,source_id,verified_at) VALUES($1,$2,'fixture','Fixture','medium','published',$3,'2026-09-10')",[line,brand,source]);
 await db.query("INSERT INTO flavor_tags(id,slug,name_ru,name_en,profile) VALUES($1,'integration-tag-a','A','A','fruit'),($2,'integration-tag-b','B','B','berry')",[tagA,tagB]);
 for(const [id,slug,name,tag] of products){
  await db.query("INSERT INTO tobacco_products(id,line_id,slug,name,name_ru,name_en,sweetness,acidity,freshness,status,source_id,verified_at) VALUES($1,$2,$3,$4,$4,$4,'subtle','subtle','subtle','published',$5,'2026-09-10')",[id,line,slug,name,source]);
  await db.query("INSERT INTO tobacco_product_tags(product_id,tag_id) VALUES($1,$2)",[id,tag]);
 }
 const cases=[["ready",products[0][0]],["substitution",products[1][0]],["missing",products[3][0]],["private-ready",products[4][0]],["denied-missing",products[5][0]]] as const;
 for(const [index,[slug,product]] of cases.entries()){
  await db.query("INSERT INTO official_mixes(id,slug,title_ru,title_en,status,source_id,verified_at) VALUES($1,$2,$2,$2,'published',$3,'2026-09-10')",[mixIds[index],`integration-${slug}`,source]);
  await db.query("INSERT INTO official_mix_components(mix_id,product_id,percentage,position) VALUES($1,$2,100,1)",[mixIds[index],product]);
 }
 const privateId="90000000-0000-4000-8000-000000000020";
 await db.query("INSERT INTO private_tobacco_products(id,user_id,brand_name,flavor_name,flavor_profiles) VALUES($1,$2,'Private','Private exact',ARRAY['berry'])",[privateId,user]);
 await db.query("INSERT INTO inventory_items(user_id,product_id,level) VALUES($1,$2,'plenty'),($1,$3,'low')",[user,products[0][0],products[2][0]]);
 await db.query("INSERT INTO inventory_items(user_id,private_product_id,level) VALUES($1,$2,'plenty')",[user,privateId]);
 await db.query("INSERT INTO substitution_deny_rules(source_product_id,substitute_product_id,reason) VALUES($1,$2,'integration deny'),($1,$3,'integration deny')",[products[5][0],products[0][0],products[2][0]]);
 const rows=(await db.query<{mixId:string;kind:string}>(inventoryMatchSQL,[user,"en"])).rows,map=new Map(rows.map(row=>[row.mixId,row.kind]));
 assert.deepEqual(mixIds.map(id=>map.get(id)),["ready","substitution","missing","ready","missing"]);
 console.log(JSON.stringify({ok:true,ready:2,substitution:1,missing:2,privateExact:true,denyRule:true,rolledBack:true}));
}finally{try{await db.query("ROLLBACK")}finally{db.release();await pool.end()}}
