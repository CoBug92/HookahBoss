import Fastify, { type FastifyInstance } from "fastify";
import type pg from "pg";
import { createAuthenticator, denyAllAdmins, hashRefreshToken, newRefreshToken, type AdminAuthorizationPolicy, type AppleTokenVerifier, unavailableAppleTokenVerifier, SessionTokenService } from "./auth.js";
import { registerAdminRoutes } from "./admin.js";
import type { AppleProviderLifecycle,ProviderTokenCipher } from "./appleProvider.js";

export type Database = Pick<pg.Pool, "query"> & Partial<Pick<pg.Pool, "connect">>;

type LocaleQuery = { locale?: "ru" | "en" };
type ArticleCategory = "fundamentals" | "preparation" | "bowls_heat" | "care" | "safety";
type ArticleListQuery = LocaleQuery & { category?: ArticleCategory; page?: string; pageSize?: string };
type ProductQuery = LocaleQuery & { brandId?: string; status?: "published" | "archived";pageSize?:string;cursor?:string };
type MixListQuery = LocaleQuery & {pageSize?:string;cursor?:string};
type IdentifierParams = { id: string };
type RatingBody = { score?: number };
type InventoryBody = { productId?: string; privateProductId?: string; level?: string };
type PersonalComponentBody = { productId?: string; privateProductId?: string; freeformName?: string; percentage?: number };
type PersonalMixBody = { clientId?: string; title?: string | null; score?: number | null; comment?: string | null; isApproximate?: boolean; components?: PersonalComponentBody[] };
type AppleExchangeBody = { identityToken?: string; authorizationCode?:string };
type RefreshBody = { refreshToken?: string };
type PrivateProductBody = { clientId?:string;brandName?:string;lineName?:string|null;flavorName?:string;flavorProfiles?:string[] };

const personalMixDetailSQL = `SELECT m.id, m.title, m.score, m.comment, m.is_approximate AS "isApproximate", m.created_at AS "createdAt", m.updated_at AS "updatedAt",
  COALESCE(json_agg(json_build_object('id',c.id,'productId',c.product_id,'privateProductId',c.private_product_id,
    'freeformName',c.freeform_name,'percentage',c.percentage,'position',c.position,
    'brandName',COALESCE(b.name,pp.brand_name),'lineName',COALESCE(l.name,pp.line_name),
    'flavorName',COALESCE(p.name,pp.flavor_name,c.freeform_name),
    'flavorProfiles',COALESCE((SELECT array_agg(DISTINCT ft.profile::text) FROM tobacco_product_tags pt JOIN flavor_tags ft ON ft.id=pt.tag_id WHERE pt.product_id=c.product_id),pp.flavor_profiles,ARRAY[]::text[])
  ) ORDER BY c.position) FILTER (WHERE c.id IS NOT NULL),'[]') AS components
 FROM personal_mixes m LEFT JOIN personal_mix_components c ON c.mix_id=m.id
 LEFT JOIN tobacco_products p ON p.id=c.product_id LEFT JOIN tobacco_lines l ON l.id=p.line_id LEFT JOIN brands b ON b.id=l.brand_id
 LEFT JOIN private_tobacco_products pp ON pp.id=c.private_product_id AND pp.user_id=m.user_id
 WHERE m.id = $1 AND m.user_id = $2 GROUP BY m.id`;

export const inventoryMatchSQL=`WITH available AS (
 SELECT i.product_id FROM inventory_items i JOIN tobacco_products p ON p.id=i.product_id AND p.status='published'
 JOIN tobacco_lines l ON l.id=p.line_id AND l.status='published' JOIN brands b ON b.id=l.brand_id AND b.status='published'
 WHERE i.user_id=$1 AND i.level<>'empty' AND i.product_id IS NOT NULL
), private_available AS (
 SELECT lower(btrim(pp.flavor_name)) flavor,pp.id FROM inventory_items i JOIN private_tobacco_products pp ON pp.id=i.private_product_id
 WHERE i.user_id=$1 AND i.level<>'empty'
), component_state AS (
 SELECT c.mix_id,c.product_id,COALESCE(CASE WHEN $2='en' THEN p.name_en ELSE p.name_ru END,p.name) AS missing_flavor,
 (a.product_id IS NOT NULL OR pa.id IS NOT NULL) exact,
 (SELECT ap.product_id FROM available ap WHERE NOT EXISTS (SELECT 1 FROM substitution_deny_rules d WHERE d.source_product_id=c.product_id AND d.substitute_product_id=ap.product_id)
  AND EXISTS (SELECT 1 FROM tobacco_product_tags st JOIN tobacco_product_tags at ON at.tag_id=st.tag_id WHERE st.product_id=c.product_id AND at.product_id=ap.product_id)
  ORDER BY ap.product_id LIMIT 1) substitute_id
 FROM official_mix_components c JOIN official_mixes m ON m.id=c.mix_id AND m.status='published'
 JOIN tobacco_products p ON p.id=c.product_id AND p.status='published' JOIN tobacco_lines pl ON pl.id=p.line_id AND pl.status='published'
 JOIN brands pb ON pb.id=pl.brand_id AND pb.status='published' LEFT JOIN available a ON a.product_id=c.product_id
 LEFT JOIN private_available pa ON pa.flavor=lower(btrim(p.name))
), classified AS (
 SELECT mix_id,count(*) FILTER(WHERE NOT exact)::int missing_count,count(*) FILTER(WHERE NOT exact AND substitute_id IS NOT NULL)::int substitution_count,
 min(missing_flavor) FILTER(WHERE NOT exact) missing_flavor,min(product_id::text) FILTER(WHERE NOT exact) source_product_id,
 min(substitute_id::text) FILTER(WHERE NOT exact AND substitute_id IS NOT NULL) substitute_product_id FROM component_state GROUP BY mix_id
) SELECT mix_id AS "mixId",CASE WHEN missing_count=0 THEN 'ready' WHEN missing_count=1 AND substitution_count=1 THEN 'substitution' WHEN missing_count=1 THEN 'missing' END kind,
 missing_flavor AS "missingFlavor",source_product_id AS "sourceProductId",substitute_product_id AS "substituteProductId"
 FROM classified WHERE missing_count=0 OR missing_count=1 ORDER BY kind,mix_id`;

function isUUID(value: string | undefined): value is string {
  return !!value && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
function hasInvalidLocale(locale: unknown): boolean { return locale !== undefined && locale !== "ru" && locale !== "en"; }
function pageSize(value:string|undefined):number|null|"invalid"{if(value===undefined)return null;const parsed=Number(value);return Number.isInteger(parsed)&&parsed>=1&&parsed<=100?parsed:"invalid"}
function encodeCursor(kind:string,id:unknown):string{return Buffer.from(JSON.stringify({v:1,k:kind,id}),"utf8").toString("base64url")}
function decodeCursor(value:string|undefined,kind:string):string|null|"invalid"{if(!value)return null;try{const data=JSON.parse(Buffer.from(value,"base64url").toString("utf8"));return data?.v===1&&data?.k===kind&&isUUID(data?.id)?data.id:"invalid"}catch{return"invalid"}}

class PersonalMixInputError extends Error {
  constructor(readonly code: string) { super(code); }
}

export function buildApp(
  database: Database,
  logger: boolean | { level: string } = false,
  tokenVerifier: AppleTokenVerifier = unavailableAppleTokenVerifier,
  adminPolicy: AdminAuthorizationPolicy = denyAllAdmins,
  appleIdentityVerifier: AppleTokenVerifier = unavailableAppleTokenVerifier,
  sessionIssuer?: SessionTokenService,
  appleProvider?:AppleProviderLifecycle,
  providerCipher?:ProviderTokenCipher
): FastifyInstance {
  const app = Fastify({ logger });
  const authenticate = createAuthenticator(database, tokenVerifier);
  registerAdminRoutes(app, database, authenticate, adminPolicy);

  app.post<{ Body: AppleExchangeBody }>("/v1/auth/apple", async (request, reply) => {
    if (!sessionIssuer || !request.body?.identityToken) return reply.code(400).send({ error: "invalid_identity_token" });
    try {
      const identity = await appleIdentityVerifier.verify(request.body.identityToken);
      let encrypted:string|undefined;
      let hasStoredProviderToken=false;
      if(appleProvider&&providerCipher){
        const existing=await database.query<{has_token:boolean}>("SELECT apple_refresh_token_encrypted IS NOT NULL AS has_token FROM app_users WHERE apple_subject=$1",[identity.subject]);
        hasStoredProviderToken=existing.rows[0]?.has_token===true;
        if(!request.body.authorizationCode&&!hasStoredProviderToken)return reply.code(401).send({error:"authorization_code_required"});
      }
      if(request.body.authorizationCode){
        if(!appleProvider||!providerCipher)return reply.code(503).send({error:"apple_provider_exchange_unavailable"});
        try{encrypted=providerCipher.encrypt(await appleProvider.exchange(request.body.authorizationCode))}catch{
          if(!hasStoredProviderToken)return reply.code(401).send({error:"invalid_authorization_code"});
        }
      }
      const user = await database.query<{ id: string; apple_subject: string; auth_session_version: number }>(
        `INSERT INTO app_users (apple_subject, email,apple_refresh_token_encrypted,apple_refresh_token_key_version) VALUES ($1, $2,$3,$4)
         ON CONFLICT (apple_subject) DO UPDATE SET email=COALESCE(app_users.email,EXCLUDED.email),updated_at=now()
         RETURNING id,apple_subject,auth_session_version`,
        [identity.subject, identity.email ?? null,encrypted??null,encrypted?providerCipher!.keyVersion:null]
      );
      if(encrypted)await database.query("UPDATE app_users SET apple_refresh_token_encrypted=$2,apple_refresh_token_key_version=$3 WHERE id=$1",[user.rows[0]!.id,encrypted,providerCipher!.keyVersion]);
      const refreshToken = newRefreshToken();
      const created = await database.query<{ id: string }>(`INSERT INTO auth_sessions(user_id,refresh_token_hash,expires_at) VALUES($1,$2,now()+interval '30 days') RETURNING id`, [user.rows[0]!.id, hashRefreshToken(refreshToken)]);
      const access = await sessionIssuer.issue({ ...identity, sessionVersion: user.rows[0]!.auth_session_version, sessionId: created.rows[0]!.id });
      return { data: { ...access, refreshToken, refreshExpiresIn: 30*24*60*60, accountId: user.rows[0]!.id } };
    } catch {
      return reply.code(401).send({ error: "invalid_identity_token" });
    }
  });

  app.post<{ Body: RefreshBody }>("/v1/auth/refresh", async (request, reply) => {
    if (!sessionIssuer || !request.body?.refreshToken || !database.connect) return reply.code(401).send({ error: "invalid_refresh_token" });
    const client = await database.connect(); const oldHash = hashRefreshToken(request.body.refreshToken);
    try {
      await client.query("BEGIN");
      const found = await client.query<{ id:string;family_id:string;user_id:string;apple_subject:string;auth_session_version:number;revoked_at:string|null;expired:boolean }>(
        `SELECT s.id,s.family_id,s.user_id,u.apple_subject,u.auth_session_version,s.revoked_at,(s.expires_at<=now()) AS expired FROM auth_sessions s JOIN app_users u ON u.id=s.user_id WHERE s.refresh_token_hash=$1 FOR UPDATE`, [oldHash]);
      const old = found.rows[0];
      if (!old || old.expired) { await client.query("ROLLBACK"); return reply.code(401).send({ error:"invalid_refresh_token" }); }
      if (old.revoked_at) { await client.query("UPDATE auth_sessions SET revoked_at=COALESCE(revoked_at,now()) WHERE family_id=$1",[old.family_id]); await client.query("COMMIT"); return reply.code(401).send({ error:"refresh_token_reused" }); }
      const refreshToken=newRefreshToken();
      const next=await client.query<{id:string}>(`INSERT INTO auth_sessions(user_id,family_id,refresh_token_hash,expires_at) VALUES($1,$2,$3,now()+interval '30 days') RETURNING id`,[old.user_id,old.family_id,hashRefreshToken(refreshToken)]);
      await client.query("UPDATE auth_sessions SET revoked_at=now(),replaced_by=$2 WHERE id=$1",[old.id,next.rows[0]!.id]); await client.query("COMMIT");
      const access=await sessionIssuer.issue({subject:old.apple_subject,sessionVersion:old.auth_session_version,sessionId:next.rows[0]!.id});
      return {data:{...access,refreshToken,refreshExpiresIn:30*24*60*60,accountId:old.user_id}};
    } catch(error){await client.query("ROLLBACK");throw error} finally {client.release()}
  });

  app.post("/v1/auth/logout", async (request, reply) => {
    const user=await authenticate(request,reply);if(!user)return;
    const authorization=request.headers.authorization!;const identity=await sessionIssuer!.verify(authorization.slice(7));
    await database.query("UPDATE auth_sessions SET revoked_at=COALESCE(revoked_at,now()) WHERE id=$1 AND user_id=$2",[identity.sessionId,user.id]);
    return reply.code(204).send();
  });

  app.delete("/v1/me/account", async (request, reply) => {
    const user = await authenticate(request, reply); if (!user) return;
    if (!database.connect) throw new Error("Transactions are unavailable");
    let providerRevocation:"revoked"|"unavailable"="unavailable";
    if(appleProvider&&providerCipher){
      const stored=await database.query<{apple_refresh_token_encrypted:string|null;apple_refresh_token_key_version:string|null}>("SELECT apple_refresh_token_encrypted,apple_refresh_token_key_version FROM app_users WHERE id=$1",[user.id]);
      const credential=stored.rows[0];
      if(credential?.apple_refresh_token_encrypted&&credential.apple_refresh_token_key_version){
        try{await appleProvider.revoke(providerCipher.decrypt(credential.apple_refresh_token_encrypted,credential.apple_refresh_token_key_version));providerRevocation="revoked"}catch{return reply.code(503).send({error:"apple_provider_revocation_failed"})}
      }
    }
    const client = await database.connect();
    try {
      await client.query("BEGIN");
      const deleted = await client.query("DELETE FROM app_users WHERE id=$1", [user.id]);
      await client.query("COMMIT");
      if (!deleted.rowCount) return reply.code(404).send({ error: "account_not_found" });
      return reply.send({data:{deleted:true,providerRevocation}});
    } catch (error) { await client.query("ROLLBACK"); throw error; } finally { client.release(); }
  });

  app.get("/health", async (_request, reply) => {
    await database.query("SELECT 1");
    return reply.send({ status: "ok" });
  });

  app.get<{ Querystring: LocaleQuery }>("/v1/brands", async (request,reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    const result = await database.query(
      `SELECT b.id, b.slug, b.name,
              json_agg(json_build_object('id', l.id, 'slug', l.slug, 'name', l.name, 'strength', l.strength)
                       ORDER BY l.name) FILTER (WHERE l.id IS NOT NULL) AS lines
         FROM brands b
         LEFT JOIN tobacco_lines l ON l.brand_id = b.id AND l.status = 'published'
        WHERE b.status = 'published'
        GROUP BY b.id
        ORDER BY b.name`
    );
    return { data: result.rows };
  });

  app.get<{ Querystring: ProductQuery }>("/v1/products", async (request, reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    if (request.query.brandId && !isUUID(request.query.brandId)) return reply.code(400).send({error:"invalid_brand_id"});
    const requestedPageSize=pageSize(request.query.pageSize),cursorId=decodeCursor(request.query.cursor,"products");
    if(requestedPageSize==="invalid"||cursorId==="invalid"||(!requestedPageSize&&request.query.cursor))return reply.code(400).send({error:"invalid_pagination"});
    const status = "published";
    const values: unknown[] = [status];
    let brandClause = "";
    if (request.query.brandId) {
      values.push(request.query.brandId);
      brandClause = ` AND b.id = $${values.length + 1}`;
    }
    let cursorClause="",limitClause="";
    if(cursorId){values.push(cursorId);cursorClause=` AND (b.name,l.name,p.name,p.id) > (SELECT cb.name,cl.name,cp.name,cp.id FROM tobacco_products cp JOIN tobacco_lines cl ON cl.id=cp.line_id JOIN brands cb ON cb.id=cl.brand_id WHERE cp.id=$${values.length+1})`;}
    if(requestedPageSize)limitClause=` LIMIT ${requestedPageSize+1}`;
    const result = await database.query(
      `SELECT p.id, p.slug, COALESCE(CASE WHEN $1::text = 'en' THEN p.name_en ELSE p.name_ru END,p.name) AS name,
              CASE WHEN $1::text = 'en' THEN p.description_en ELSE p.description_ru END AS description,
              p.translation_origin AS "translationOrigin", p.source_confidence AS "sourceConfidence",
              p.sweetness, p.acidity, p.freshness,
              l.id AS line_id, l.name AS line_name, l.strength, b.id AS brand_id, b.name AS brand_name,
              COALESCE(json_agg(json_build_object('id', t.id, 'slug', t.slug,
                'name', CASE WHEN $1::text = 'en' THEN t.name_en ELSE t.name_ru END,
                'profile', t.profile, 'weight', pt.weight)) FILTER (WHERE t.id IS NOT NULL), '[]') AS tags
         FROM tobacco_products p
         JOIN tobacco_lines l ON l.id = p.line_id
         JOIN brands b ON b.id = l.brand_id
         LEFT JOIN tobacco_product_tags pt ON pt.product_id = p.id
         LEFT JOIN flavor_tags t ON t.id = pt.tag_id
        WHERE p.status = $2 AND l.status = 'published' AND b.status = 'published'${brandClause}${cursorClause}
        GROUP BY p.id, l.id, b.id
        ORDER BY b.name, l.name, p.name, p.id${limitClause}`,
      [request.query.locale ?? "ru", ...values]
    );
    if(!requestedPageSize)return {data:result.rows};const hasMore=result.rows.length>requestedPageSize,data=result.rows.slice(0,requestedPageSize),nextCursor=hasMore?encodeCursor("products",(data.at(-1) as {id:unknown}).id):null;
    return {data,pagination:{nextCursor,hasMore}};
  });

  app.get<{ Querystring: MixListQuery }>("/v1/mixes", async (request,reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    const requestedPageSize=pageSize(request.query.pageSize),cursorId=decodeCursor(request.query.cursor,"mixes");if(requestedPageSize==="invalid"||cursorId==="invalid"||(!requestedPageSize&&request.query.cursor))return reply.code(400).send({error:"invalid_pagination"});
    const locale = request.query.locale ?? "ru";
    const values:unknown[]=[locale];let cursorClause="";if(cursorId){values.push(cursorId);cursorClause=` AND (SELECT CASE WHEN cm.published_at IS NULL THEN m.published_at IS NULL AND (m.title_ru,m.id)>(cm.title_ru,cm.id) ELSE m.published_at IS NULL OR m.published_at<cm.published_at OR (m.published_at=cm.published_at AND (m.title_ru,m.id)>(cm.title_ru,cm.id)) END FROM official_mixes cm WHERE cm.id=$2)`;}
    const limitClause=requestedPageSize?` LIMIT ${requestedPageSize+1}`:"";
    const result = await database.query(
      `SELECT m.id, m.slug, CASE WHEN $1 = 'en' THEN m.title_en ELSE m.title_ru END AS title,
              CASE WHEN $1 = 'en' THEN m.summary_en ELSE m.summary_ru END AS summary,
              stats.rating, stats.ratings_count,
              COALESCE(parts.components,'[]') AS components,
              COALESCE(parts.tags,ARRAY[]::text[]) AS tags, COALESCE(parts.profiles,ARRAY[]::text[]) AS profiles,
              COALESCE(parts.sweetness,'subtle') AS sweetness, COALESCE(parts.acidity,'subtle') AS acidity,
              COALESCE(parts.freshness,'subtle') AS freshness, COALESCE(parts.strength,'medium') AS strength
         FROM official_mixes m
         LEFT JOIN LATERAL (SELECT round(avg(score)::numeric,1)::float rating,count(*)::int ratings_count FROM mix_ratings WHERE mix_id=m.id) stats ON true
         LEFT JOIN LATERAL (
           SELECT (SELECT json_agg(json_build_object('productId',cp.id,'brand',cb.name,'line',cl.name,
                    'flavor',COALESCE(CASE WHEN $1='en' THEN cp.name_en ELSE cp.name_ru END,cp.name),
                    'percentage',cc.percentage,'position',cc.position) ORDER BY cc.position)
                    FROM official_mix_components cc JOIN tobacco_products cp ON cp.id=cc.product_id
                    JOIN tobacco_lines cl ON cl.id=cp.line_id JOIN brands cb ON cb.id=cl.brand_id
                    WHERE cc.mix_id=m.id) components,
                  array_agg(DISTINCT CASE WHEN $1='en' THEN t.name_en ELSE t.name_ru END) FILTER (WHERE t.id IS NOT NULL) tags,
                  array_agg(DISTINCT t.profile) FILTER (WHERE t.id IS NOT NULL) profiles,
                  CASE WHEN bool_or(p.sweetness='pronounced') THEN 'pronounced' ELSE 'subtle' END sweetness,
                  CASE WHEN bool_or(p.acidity='pronounced') THEN 'pronounced' ELSE 'subtle' END acidity,
                  CASE WHEN bool_or(p.freshness='pronounced') THEN 'pronounced' ELSE 'subtle' END freshness,
                  CASE max(CASE l.strength WHEN 'strong' THEN 3 WHEN 'medium' THEN 2 ELSE 1 END) WHEN 3 THEN 'strong' WHEN 2 THEN 'medium' ELSE 'light' END strength
             FROM official_mix_components c JOIN tobacco_products p ON p.id=c.product_id
             JOIN tobacco_lines l ON l.id=p.line_id JOIN brands b ON b.id=l.brand_id
             LEFT JOIN tobacco_product_tags pt ON pt.product_id=p.id LEFT JOIN flavor_tags t ON t.id=pt.tag_id
            WHERE c.mix_id=m.id
         ) parts ON true
        WHERE m.status = 'published'${cursorClause} AND NOT EXISTS (
          SELECT 1 FROM official_mix_components vc JOIN tobacco_products vp ON vp.id=vc.product_id
          JOIN tobacco_lines vl ON vl.id=vp.line_id JOIN brands vb ON vb.id=vl.brand_id
          WHERE vc.mix_id=m.id AND (vp.status<>'published' OR vl.status<>'published' OR vb.status<>'published'))
        ORDER BY m.published_at DESC NULLS LAST, m.title_ru, m.id${limitClause}`,
      values
    );
    if(!requestedPageSize)return {data:result.rows};const hasMore=result.rows.length>requestedPageSize,data=result.rows.slice(0,requestedPageSize),nextCursor=hasMore?encodeCursor("mixes",(data.at(-1) as {id:unknown}).id):null;return{data,pagination:{nextCursor,hasMore}};
  });

  app.get<{ Params: IdentifierParams; Querystring: LocaleQuery }>("/v1/mixes/:id", async (request, reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    if (!isUUID(request.params.id)) return reply.code(400).send({ error: "invalid_mix_id" });
    const locale = request.query.locale ?? "ru";
    const result = await database.query(
      `SELECT m.id,m.slug,CASE WHEN $2='en' THEN m.title_en ELSE m.title_ru END title,
              CASE WHEN $2='en' THEN m.summary_en ELSE m.summary_ru END summary,stats.rating,stats.ratings_count,
              COALESCE(parts.components,'[]') components,COALESCE(parts.tags,ARRAY[]::text[]) tags,COALESCE(parts.profiles,ARRAY[]::text[]) profiles,
              COALESCE(parts.sweetness,'subtle') sweetness,COALESCE(parts.acidity,'subtle') acidity,
              COALESCE(parts.freshness,'subtle') freshness,COALESCE(parts.strength,'medium') strength
         FROM official_mixes m
         LEFT JOIN LATERAL (SELECT round(avg(score)::numeric,1)::float rating,count(*)::int ratings_count FROM mix_ratings WHERE mix_id=m.id) stats ON true
         LEFT JOIN LATERAL (
           SELECT (SELECT json_agg(json_build_object('productId',cp.id,'brand',cb.name,'line',cl.name,
                    'flavor',COALESCE(CASE WHEN $2='en' THEN cp.name_en ELSE cp.name_ru END,cp.name),
                    'percentage',cc.percentage,'position',cc.position) ORDER BY cc.position)
                    FROM official_mix_components cc JOIN tobacco_products cp ON cp.id=cc.product_id JOIN tobacco_lines cl ON cl.id=cp.line_id JOIN brands cb ON cb.id=cl.brand_id WHERE cc.mix_id=m.id) components,
                  array_agg(DISTINCT CASE WHEN $2='en' THEN t.name_en ELSE t.name_ru END) FILTER(WHERE t.id IS NOT NULL) tags,
                  array_agg(DISTINCT t.profile) FILTER(WHERE t.id IS NOT NULL) profiles,
                  CASE WHEN bool_or(p.sweetness='pronounced') THEN 'pronounced' ELSE 'subtle' END sweetness,
                  CASE WHEN bool_or(p.acidity='pronounced') THEN 'pronounced' ELSE 'subtle' END acidity,
                  CASE WHEN bool_or(p.freshness='pronounced') THEN 'pronounced' ELSE 'subtle' END freshness,
                  CASE max(CASE l.strength WHEN 'strong' THEN 3 WHEN 'medium' THEN 2 ELSE 1 END) WHEN 3 THEN 'strong' WHEN 2 THEN 'medium' ELSE 'light' END strength
             FROM official_mix_components c JOIN tobacco_products p ON p.id=c.product_id JOIN tobacco_lines l ON l.id=p.line_id
             LEFT JOIN tobacco_product_tags pt ON pt.product_id=p.id LEFT JOIN flavor_tags t ON t.id=pt.tag_id WHERE c.mix_id=m.id) parts ON true
        WHERE m.id=$1 AND m.status='published' AND NOT EXISTS (
          SELECT 1 FROM official_mix_components vc JOIN tobacco_products vp ON vp.id=vc.product_id
          JOIN tobacco_lines vl ON vl.id=vp.line_id JOIN brands vb ON vb.id=vl.brand_id
          WHERE vc.mix_id=m.id AND (vp.status<>'published' OR vl.status<>'published' OR vb.status<>'published'))`,
      [request.params.id, locale]
    );
    if (!result.rows[0]) return reply.code(404).send({ error: "mix_not_found" });
    return { data: result.rows[0] };
  });

  app.get<{ Querystring: ArticleListQuery }>("/v1/articles", async (request, reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    const locale = request.query.locale ?? "ru";
    const articleCategories: ArticleCategory[] = ["fundamentals", "preparation", "bowls_heat", "care", "safety"];
    if (request.query.category && !articleCategories.includes(request.query.category)) {
      return reply.code(400).send({ error: "invalid_category" });
    }
    const page = request.query.page === undefined ? 1 : Number(request.query.page);
    const pageSize = request.query.pageSize === undefined ? 20 : Number(request.query.pageSize);
    if (!Number.isInteger(page) || page < 1 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) {
      return reply.code(400).send({ error: "invalid_pagination" });
    }
    const values: unknown[] = [locale];
    let categoryClause = "";
    if (request.query.category) {
      values.push(request.query.category);
      categoryClause = ` AND category = $${values.length}::article_category`;
    }
    values.push(pageSize, (page - 1) * pageSize);
    const result = await database.query(
      `SELECT id, slug,
              CASE WHEN $1 = 'en' THEN title_en ELSE title_ru END AS title,
              COALESCE(CASE WHEN $1 = 'en' THEN summary_en ELSE summary_ru END,'') AS summary,
              category, reading_minutes AS "readingMinutes",
              count(*) OVER()::int AS "totalCount"
         FROM articles WHERE status = 'published'${categoryClause}
        ORDER BY published_at DESC NULLS LAST, slug
        LIMIT $${values.length - 1} OFFSET $${values.length}`,
      values
    );
    let total = Number(result.rows[0]?.totalCount ?? 0);
    if(result.rows.length===0){
      const countValues:unknown[]=[];let countClause="";
      if(request.query.category){countValues.push(request.query.category);countClause=" WHERE category=$1::article_category";}
      const count=await database.query(`SELECT count(*)::int AS total FROM articles${countClause}${countClause?" AND":" WHERE"} status='published'`,countValues);
      total=Number((count.rows[0] as {total?:number}|undefined)?.total??0);
    }
    return { data: result.rows.map(({ totalCount: _totalCount, ...row }) => row), pagination: { page, pageSize, total } };
  });

  app.get<{ Params: IdentifierParams; Querystring: LocaleQuery }>("/v1/articles/:id", async (request, reply) => {
    if(hasInvalidLocale(request.query.locale))return reply.code(400).send({error:"invalid_locale"});
    const locale = request.query.locale ?? "ru";
    const result = await database.query(
      `SELECT a.id, a.slug,
              CASE WHEN $2 = 'en' THEN a.title_en ELSE a.title_ru END AS title,
              COALESCE(CASE WHEN $2 = 'en' THEN a.summary_en ELSE a.summary_ru END,'') AS summary,
              COALESCE(CASE WHEN $2 = 'en' THEN a.body_en_structured ELSE a.body_ru_structured END,'[]'::jsonb) AS sections,
              a.category, a.reading_minutes AS "readingMinutes",
              COALESCE((SELECT json_agg(json_build_object(
                'id', r.id, 'slug', r.slug,
                'title', CASE WHEN $2 = 'en' THEN r.title_en ELSE r.title_ru END,
                'summary', CASE WHEN $2 = 'en' THEN r.summary_en ELSE r.summary_ru END,
                'category', r.category, 'readingMinutes', r.reading_minutes
              ) ORDER BY ar.position)
                FROM article_related ar JOIN articles r ON r.id = ar.related_article_id
               WHERE ar.article_id = a.id AND r.status = 'published'), '[]') AS related
         FROM articles a
        WHERE (a.id::text = $1 OR a.slug = $1) AND a.status = 'published'`,
      [request.params.id, locale]
    );
    if (!result.rows[0]) return reply.code(404).send({ error: "article_not_found" });
    return { data: result.rows[0] };
  });

  app.put<{ Params: IdentifierParams; Body: RatingBody }>("/v1/me/ratings/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    if (!isUUID(request.params.id)) return reply.code(400).send({ error: "invalid_mix_id" });
    const score = request.body?.score;
    if (!Number.isInteger(score) || score! < 1 || score! > 5) return reply.code(400).send({ error: "invalid_score" });

    const result = await database.query(
      `INSERT INTO mix_ratings (user_id, mix_id, score)
       SELECT $1, id, $3 FROM official_mixes WHERE id = $2 AND status = 'published'
       ON CONFLICT (user_id, mix_id) DO UPDATE SET score = EXCLUDED.score, updated_at = now()
       RETURNING mix_id AS "mixId", score, updated_at AS "updatedAt"`,
      [user.id, request.params.id, score]
    );
    if (!result.rows[0]) return reply.code(404).send({ error: "mix_not_found" });
    return { data: result.rows[0] };
  });

  app.delete<{ Params: IdentifierParams }>("/v1/me/ratings/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    if (!isUUID(request.params.id)) return reply.code(400).send({ error: "invalid_mix_id" });
    await database.query("DELETE FROM mix_ratings WHERE user_id = $1 AND mix_id = $2", [user.id, request.params.id]);
    return reply.code(204).send();
  });

  app.put<{ Params: IdentifierParams }>("/v1/me/favorites/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    if (!isUUID(request.params.id)) return reply.code(400).send({ error: "invalid_mix_id" });
    const result = await database.query(
      `INSERT INTO mix_favorites (user_id, mix_id)
       SELECT $1, id FROM official_mixes WHERE id = $2 AND status = 'published'
       ON CONFLICT (user_id, mix_id) DO UPDATE SET created_at = mix_favorites.created_at
       RETURNING mix_id AS "mixId", created_at AS "createdAt"`,
      [user.id, request.params.id]
    );
    if (!result.rows[0]) return reply.code(404).send({ error: "mix_not_found" });
    return { data: result.rows[0] };
  });

  app.delete<{ Params: IdentifierParams }>("/v1/me/favorites/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    if (!isUUID(request.params.id)) return reply.code(400).send({ error: "invalid_mix_id" });
    await database.query("DELETE FROM mix_favorites WHERE user_id = $1 AND mix_id = $2", [user.id, request.params.id]);
    return reply.code(204).send();
  });

  app.get("/v1/me/library", async (request, reply) => {
    const user = await authenticate(request, reply); if (!user) return;
    const [favorites, ratings, inventory, personalMixes, articleBookmarks] = await Promise.all([
      database.query(`SELECT mix_id AS "mixId",created_at AS "createdAt" FROM mix_favorites WHERE user_id=$1 ORDER BY created_at DESC`,[user.id]),
      database.query(`SELECT mix_id AS "mixId",score,updated_at AS "updatedAt" FROM mix_ratings WHERE user_id=$1 ORDER BY updated_at DESC`,[user.id]),
      database.query(`SELECT i.id,i.level,i.product_id AS "productId",i.private_product_id AS "privateProductId",COALESCE(p.name,pp.flavor_name) AS "flavorName",COALESCE(b.name,pp.brand_name) AS "brandName",COALESCE(l.name,pp.line_name) AS "lineName",i.updated_at AS "updatedAt" FROM inventory_items i LEFT JOIN tobacco_products p ON p.id=i.product_id LEFT JOIN tobacco_lines l ON l.id=p.line_id LEFT JOIN brands b ON b.id=l.brand_id LEFT JOIN private_tobacco_products pp ON pp.id=i.private_product_id AND pp.user_id=i.user_id WHERE i.user_id=$1 ORDER BY "brandName","flavorName"`,[user.id]),
      database.query(`SELECT m.id,m.title,m.score,m.comment,m.created_at AS "createdAt",m.updated_at AS "updatedAt",count(c.id)::int AS "componentCount" FROM personal_mixes m LEFT JOIN personal_mix_components c ON c.mix_id=m.id WHERE m.user_id=$1 GROUP BY m.id ORDER BY m.updated_at DESC`,[user.id]),
      database.query(`SELECT a.slug FROM article_bookmarks ab JOIN articles a ON a.id=ab.article_id WHERE ab.user_id=$1 AND a.status='published' ORDER BY ab.created_at DESC`,[user.id])
    ]);
    return {data:{favorites:favorites.rows,ratings:ratings.rows,inventory:inventory.rows,personalMixes:personalMixes.rows,articleBookmarks:articleBookmarks.rows.map(row=>(row as {slug:string}).slug)}};
  });

  app.get("/v1/me/private-products",async(request,reply)=>{const user=await authenticate(request,reply);if(!user)return;const result=await database.query(`SELECT id,brand_name AS "brandName",line_name AS "lineName",flavor_name AS "flavorName",flavor_profiles AS "flavorProfiles",created_at AS "createdAt" FROM private_tobacco_products WHERE user_id=$1 ORDER BY brand_name,flavor_name`,[user.id]);return{data:result.rows}});
  app.post<{Body:PrivateProductBody}>("/v1/me/private-products",async(request,reply)=>{const user=await authenticate(request,reply);if(!user)return;const brand=request.body?.brandName?.trim(),flavor=request.body?.flavorName?.trim(),line=request.body?.lineName?.trim()||null,profiles=request.body?.flavorProfiles??[];const allowed=new Set(['berry','fruit','citrus','dessert','beverage','herbal','spicy','fresh']);if((request.body?.clientId&&!isUUID(request.body.clientId))||!brand||!flavor||!Array.isArray(profiles)||profiles.some(p=>!allowed.has(p)))return reply.code(400).send({error:'invalid_private_product'});const result=await database.query(`INSERT INTO private_tobacco_products(id,user_id,brand_name,line_name,flavor_name,flavor_profiles) VALUES(COALESCE($1::uuid,gen_random_uuid()),$2,$3,$4,$5,$6) ON CONFLICT(id) DO UPDATE SET flavor_profiles=private_tobacco_products.flavor_profiles WHERE private_tobacco_products.user_id=$2 RETURNING id,brand_name AS "brandName",line_name AS "lineName",flavor_name AS "flavorName",flavor_profiles AS "flavorProfiles",created_at AS "createdAt"`,[request.body.clientId??null,user.id,brand,line,flavor,profiles]);if(!result.rows[0])return reply.code(409).send({error:'client_id_conflict'});return reply.code(201).send({data:result.rows[0]})});
  app.delete<{Params:IdentifierParams}>("/v1/me/private-products/:id",async(request,reply)=>{const user=await authenticate(request,reply);if(!user)return;if(!isUUID(request.params.id))return reply.code(400).send({error:'invalid_private_product_id'});await database.query(`DELETE FROM private_tobacco_products WHERE id=$1 AND user_id=$2`,[request.params.id,user.id]);return reply.code(204).send()});

  app.put<{Params:IdentifierParams}>("/v1/me/article-bookmarks/:id",async(request,reply)=>{const user=await authenticate(request,reply);if(!user)return;const result=await database.query(`INSERT INTO article_bookmarks(user_id,article_id) SELECT $1,id FROM articles WHERE (id::text=$2 OR slug=$2) AND status='published' ON CONFLICT DO NOTHING RETURNING article_id`,[user.id,request.params.id]);if(!result.rows[0])return reply.code(404).send({error:'article_not_found'});return reply.code(204).send()});
  app.delete<{Params:IdentifierParams}>("/v1/me/article-bookmarks/:id",async(request,reply)=>{const user=await authenticate(request,reply);if(!user)return;await database.query(`DELETE FROM article_bookmarks USING articles WHERE article_bookmarks.article_id=articles.id AND article_bookmarks.user_id=$1 AND (articles.id::text=$2 OR articles.slug=$2)`,[user.id,request.params.id]);return reply.code(204).send()});

  app.get("/v1/me/inventory", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    const result = await database.query(
      `SELECT i.id, i.level, i.product_id AS "productId", i.private_product_id AS "privateProductId",
              COALESCE(p.name, pp.flavor_name) AS "flavorName",
              COALESCE(b.name, pp.brand_name) AS "brandName",
              COALESCE(l.name, pp.line_name) AS "lineName", i.updated_at AS "updatedAt"
         FROM inventory_items i
         LEFT JOIN tobacco_products p ON p.id = i.product_id
         LEFT JOIN tobacco_lines l ON l.id = p.line_id
         LEFT JOIN brands b ON b.id = l.brand_id
         LEFT JOIN private_tobacco_products pp ON pp.id = i.private_product_id AND pp.user_id = i.user_id
        WHERE i.user_id = $1 ORDER BY "brandName", "flavorName"`,
      [user.id]
    );
    return { data: result.rows };
  });

  app.get<{Querystring:LocaleQuery}>("/v1/me/inventory/matches", async (request, reply) => {
    const user = await authenticate(request, reply); if (!user) return;
    const locale=request.query.locale ?? "ru";
    const result = await database.query(inventoryMatchSQL,[user.id,locale]);
    return {data:result.rows};
  });

  app.put<{ Body: InventoryBody }>("/v1/me/inventory", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    const { productId, privateProductId, level } = request.body ?? {};
    if ((productId ? 1 : 0) + (privateProductId ? 1 : 0) !== 1) {
      return reply.code(400).send({ error: "exactly_one_product_required" });
    }
    if ((productId && !isUUID(productId)) || (privateProductId && !isUUID(privateProductId))) return reply.code(400).send({error:"invalid_product_id"});
    if (!level || !["plenty", "low", "empty"].includes(level)) {
      return reply.code(400).send({ error: "invalid_inventory_level" });
    }

    const result = productId
      ? await database.query(
          `WITH changed AS (INSERT INTO inventory_items (user_id, product_id, level)
           SELECT $1, id, $3::inventory_level FROM tobacco_products WHERE id = $2
           ON CONFLICT (user_id, product_id) WHERE product_id IS NOT NULL
           DO UPDATE SET level = EXCLUDED.level, updated_at = now()
           RETURNING *) SELECT changed.id,changed.product_id AS "productId",changed.private_product_id AS "privateProductId",changed.level,
           p.name AS "flavorName",b.name AS "brandName",l.name AS "lineName",changed.updated_at AS "updatedAt"
           FROM changed JOIN tobacco_products p ON p.id=changed.product_id JOIN tobacco_lines l ON l.id=p.line_id JOIN brands b ON b.id=l.brand_id`,
          [user.id, productId, level]
        )
      : await database.query(
          `WITH changed AS (INSERT INTO inventory_items (user_id, private_product_id, level)
           SELECT $1, id, $3::inventory_level FROM private_tobacco_products WHERE id = $2 AND user_id = $1
           ON CONFLICT (user_id, private_product_id) WHERE private_product_id IS NOT NULL
           DO UPDATE SET level = EXCLUDED.level, updated_at = now()
           RETURNING *) SELECT changed.id,changed.product_id AS "productId",changed.private_product_id AS "privateProductId",changed.level,
           pp.flavor_name AS "flavorName",pp.brand_name AS "brandName",pp.line_name AS "lineName",changed.updated_at AS "updatedAt"
           FROM changed JOIN private_tobacco_products pp ON pp.id=changed.private_product_id AND pp.user_id=$1`,
          [user.id, privateProductId, level]
        );
    if (!result.rows[0]) return reply.code(404).send({ error: "product_not_found" });
    return { data: result.rows[0] };
  });

  app.delete<{ Params: IdentifierParams }>("/v1/me/inventory/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    if (!isUUID(request.params.id)) return reply.code(400).send({error:"invalid_inventory_item_id"});
    const result = await database.query("DELETE FROM inventory_items WHERE id = $1 AND user_id = $2 RETURNING id", [request.params.id, user.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: "inventory_item_not_found" });
    return reply.code(204).send();
  });

  app.get("/v1/me/personal-mixes", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    const result = await database.query(
      `SELECT m.id, m.title, m.score, m.comment, m.is_approximate AS "isApproximate", m.created_at AS "createdAt", m.updated_at AS "updatedAt",
              count(c.id)::int AS "componentCount"
         FROM personal_mixes m
         LEFT JOIN personal_mix_components c ON c.mix_id = m.id
        WHERE m.user_id = $1
        GROUP BY m.id ORDER BY m.updated_at DESC`,
      [user.id]
    );
    return { data: result.rows };
  });

  app.get<{ Params: IdentifierParams }>("/v1/me/personal-mixes/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    const result = await database.query(personalMixDetailSQL,[request.params.id,user.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: "personal_mix_not_found" });
    return { data: result.rows[0] };
  });

  app.post<{ Body: PersonalMixBody }>("/v1/me/personal-mixes", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    let input: ValidPersonalMixInput;
    if (request.body?.clientId && !isUUID(request.body.clientId)) return reply.code(400).send({error:"invalid_client_id"});
    try { input = validatePersonalMix(request.body); }
    catch (error) { return sendPersonalMixInputError(error, reply); }

    try {
      const data = await writePersonalMix(database, user.id, null, input, request.body.clientId);
      return reply.code(201).send({ data });
    } catch (error) {
      if (error instanceof PersonalMixInputError) return reply.code(400).send({ error: error.code });
      throw error;
    }
  });

  app.put<{ Params: IdentifierParams; Body: PersonalMixBody }>("/v1/me/personal-mixes/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    let input: ValidPersonalMixInput;
    try { input = validatePersonalMix(request.body); }
    catch (error) { return sendPersonalMixInputError(error, reply); }

    try {
      const data = await writePersonalMix(database, user.id, request.params.id, input);
      if (!data) return reply.code(404).send({ error: "personal_mix_not_found" });
      return { data };
    } catch (error) {
      if (error instanceof PersonalMixInputError) return reply.code(400).send({ error: error.code });
      throw error;
    }
  });

  app.delete<{ Params: IdentifierParams }>("/v1/me/personal-mixes/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return;
    const result = await database.query("DELETE FROM personal_mixes WHERE id = $1 AND user_id = $2 RETURNING id", [request.params.id, user.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: "personal_mix_not_found" });
    return reply.code(204).send();
  });

  app.setErrorHandler((error, _request, reply) => {
    app.log.error(error);
    reply.code(500).send({ error: "internal_error" });
  });

  return app;
}

type ValidPersonalMixInput = {
  title: string | null;
  score: number | null;
  comment: string | null;
  isApproximate: boolean;
  components: Array<{
    productId?: string;
    privateProductId?: string;
    freeformName?: string;
    percentage: number | null;
  }>;
};

function validatePersonalMix(body: PersonalMixBody | undefined): ValidPersonalMixInput {
  if (!body || !Array.isArray(body.components) || body.components.length < 1) throw new PersonalMixInputError("components_required");
  if (body.score != null && (!Number.isInteger(body.score) || body.score < 1 || body.score > 5)) throw new PersonalMixInputError("invalid_score");

  const components = body.components.map(component => {
    const freeformName = component.freeformName?.trim();
    const sourceCount = (component.productId ? 1 : 0) + (component.privateProductId ? 1 : 0) + (freeformName ? 1 : 0);
    if (sourceCount !== 1) throw new PersonalMixInputError("exactly_one_component_source_required");
    if (component.percentage != null && (!Number.isInteger(component.percentage) || component.percentage < 1 || component.percentage > 100)) {
      throw new PersonalMixInputError("invalid_percentage");
    }
    return { ...component, freeformName, percentage: component.percentage ?? null };
  });

  const percentageCount = components.filter(component => component.percentage != null).length;
  if (percentageCount !== 0 && percentageCount !== components.length) throw new PersonalMixInputError("partial_percentages_not_allowed");
  if (percentageCount === components.length && components.reduce((sum, component) => sum + (component.percentage ?? 0), 0) !== 100) {
    throw new PersonalMixInputError("percentages_must_total_100");
  }

  return {
    title: body.title?.trim() || null,
    score: body.score ?? null,
    comment: body.comment?.trim() || null,
    isApproximate: body.isApproximate === true,
    components
  };
}

function sendPersonalMixInputError(error: unknown, reply: import("fastify").FastifyReply) {
  if (error instanceof PersonalMixInputError) return reply.code(400).send({ error: error.code });
  throw error;
}

async function writePersonalMix(database: Database, userId: string, mixId: string | null, input: ValidPersonalMixInput, createId?:string) {
  if (!database.connect) throw new Error("Database transactions are unavailable");
  const client = await database.connect();
  try {
    await client.query("BEGIN");
    let id: string;
    if (mixId) {
      const updated = await client.query<{ id: string }>(
        `UPDATE personal_mixes SET title = $3, score = $4, comment = $5, is_approximate = $6, updated_at = now()
          WHERE id = $1 AND user_id = $2 RETURNING id`,
        [mixId, userId, input.title, input.score, input.comment, input.isApproximate]
      );
      if (!updated.rows[0]) { await client.query("ROLLBACK"); return null; }
      id = updated.rows[0].id;
      await client.query("DELETE FROM personal_mix_components WHERE mix_id = $1", [id]);
    } else {
      const inserted = await client.query<{ id: string; inserted:boolean }>(
        `INSERT INTO personal_mixes (id,user_id,title,score,comment,is_approximate) VALUES (COALESCE($1::uuid,gen_random_uuid()),$2,$3,$4,$5,$6)
         ON CONFLICT(id) DO UPDATE SET updated_at=personal_mixes.updated_at WHERE personal_mixes.user_id=$2
         RETURNING id,(xmax=0) AS inserted`,
        [createId ?? null,userId, input.title, input.score, input.comment, input.isApproximate]
      );
      if (!inserted.rows[0]) throw new PersonalMixInputError("client_id_conflict");
      id = inserted.rows[0]!.id;
      if (inserted.rows[0]!.inserted === false) { const persisted=await client.query(personalMixDetailSQL,[id,userId]);await client.query("COMMIT");return persisted.rows[0]; }
    }

    for (const [index, component] of input.components.entries()) {
      let result;
      if (component.productId) {
        result = await client.query(
          `INSERT INTO personal_mix_components (mix_id, product_id, percentage, position)
           SELECT $1, id, $3, $4 FROM tobacco_products WHERE id = $2 RETURNING id`,
          [id, component.productId, component.percentage, index + 1]
        );
      } else if (component.privateProductId) {
        result = await client.query(
          `INSERT INTO personal_mix_components (mix_id, private_product_id, percentage, position)
           SELECT $1, id, $3, $4 FROM private_tobacco_products WHERE id = $2 AND user_id = $5 RETURNING id`,
          [id, component.privateProductId, component.percentage, index + 1, userId]
        );
      } else {
        result = await client.query(
          `INSERT INTO personal_mix_components (mix_id, freeform_name, percentage, position)
           VALUES ($1, $2, $3, $4) RETURNING id`,
          [id, component.freeformName, component.percentage, index + 1]
        );
      }
      if (!result.rows[0]) throw new PersonalMixInputError("component_source_not_found");
    }

    const persisted=await client.query(personalMixDetailSQL,[id,userId]);
    if(!persisted.rows[0])throw new Error("Personal mix hydration failed");
    await client.query("COMMIT");
    return persisted.rows[0];
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
