import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { AdminAuthorizationPolicy, AuthenticatedUser } from "./auth.js";
import type { Database } from "./app.js";

type Authenticator = (request: FastifyRequest, reply: FastifyReply) => Promise<AuthenticatedUser | null>;
type Body = Record<string, unknown>;
type Params = { id: string };
type ListQuery = { limit?: string; offset?: string; status?: string; brandId?: string; lineId?: string };

type SimpleResource = {
  path: string;
  table: string;
  fields: Record<string, string>;
  required: string[];
  localized?: string[];
  provenance?: boolean;
  orderBy?: string;
};

const resources: SimpleResource[] = [
  { path: "sources", table: "content_sources", fields: { url: "url", title: "title", publisher: "publisher", checkedAt: "checked_at" }, required: ["url", "checkedAt"], orderBy: "created_at DESC" },
  { path: "brands", table: "brands", fields: { slug: "slug", name: "name", status: "status", sourceId: "source_id", verifiedAt: "verified_at" }, required: ["slug", "name"], provenance: true, orderBy: "created_at DESC" },
  { path: "lines", table: "tobacco_lines", fields: { brandId: "brand_id", slug: "slug", name: "name", strength: "strength", status: "status", sourceId: "source_id", verifiedAt: "verified_at" }, required: ["brandId", "slug", "name", "strength"], provenance: true, orderBy: "name" },
  { path: "flavor-tags", table: "flavor_tags", fields: { slug: "slug", nameRu: "name_ru", nameEn: "name_en", profile: "profile" }, required: ["slug", "nameRu", "nameEn", "profile"], localized: ["nameRu", "nameEn"], orderBy: "slug" },
  { path: "articles", table: "articles", fields: { slug: "slug", titleRu: "title_ru", titleEn: "title_en", summaryRu:"summary_ru",summaryEn:"summary_en",bodyRu: "body_ru", bodyEn: "body_en",bodyRuStructured:"body_ru_structured",bodyEnStructured:"body_en_structured",category:"category",readingMinutes:"reading_minutes",status: "status", sourceId: "source_id", verifiedAt: "verified_at", publishedAt: "published_at" }, required: ["slug", "titleRu", "titleEn", "summaryRu","summaryEn","bodyRuStructured","bodyEnStructured","category","readingMinutes"], localized: ["titleRu", "titleEn", "summaryRu","summaryEn"], provenance: true, orderBy: "created_at DESC" }
];

export function registerAdminRoutes(
  app: FastifyInstance,
  database: Database,
  authenticate: Authenticator,
  policy: AdminAuthorizationPolicy
) {
  const requireAdmin = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = await authenticate(request, reply);
    if (!user) return null;
    if (!(await policy.allows(user))) {
      reply.code(403).send({ error: "forbidden" });
      return null;
    }
    return user;
  };

  app.get("/v1/me/admin-capabilities",async(request,reply)=>{
    const user=await authenticate(request,reply);if(!user)return;
    return {data:{admin:await policy.allows(user)}};
  });

  for (const resource of resources) registerSimpleCrud(app, database, requireAdmin, resource);
  registerProducts(app, database, requireAdmin);
  registerOfficialMixes(app, database, requireAdmin);
  registerDenyRules(app, database, requireAdmin);
}

function registerSimpleCrud(app: FastifyInstance, database: Database, requireAdmin: Authenticator, resource: SimpleResource) {
  const base = `/v1/admin/${resource.path}`;
  app.get<{ Querystring: ListQuery }>(base, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const { limit, offset } = pagination(request.query);
    const values: unknown[] = [];
    const clauses: string[] = [];
    if (resource.provenance && request.query.status) {
      values.push(request.query.status); clauses.push(`status = $${values.length}`);
    }
    values.push(limit, offset);
    const where = clauses.length ? `WHERE ${clauses.join(" AND ")}` : "";
    const result = await database.query(`SELECT * FROM ${resource.table} ${where} ORDER BY ${resource.orderBy ?? "id"} LIMIT $${values.length - 1} OFFSET $${values.length}`, values);
    return { data: result.rows, pagination: { limit, offset } };
  });

  app.get<{ Params: Params }>(`${base}/:id`, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const result = await database.query(`SELECT * FROM ${resource.table} WHERE id = $1`, [request.params.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: `${resource.path}_not_found` });
    return { data: result.rows[0] };
  });

  app.post<{ Body: Body }>(base, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const error = validateResource(request.body, resource, true);
    if (error) return reply.code(400).send({ error });
    const { columns, values } = mappedValues(request.body, resource.fields);
    const placeholders = values.map((_, index) => `$${index + 1}`);
    const result = await database.query(`INSERT INTO ${resource.table} (${columns.join(", ")}) VALUES (${placeholders.join(", ")}) RETURNING *`, values);
    return reply.code(201).send({ data: result.rows[0] });
  });

  app.put<{ Params: Params; Body: Body }>(`${base}/:id`, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const error = validateResource(request.body, resource, false);
    if (error) return reply.code(400).send({ error });
    const { columns, values } = mappedValues(request.body, resource.fields);
    if (!columns.length) return reply.code(400).send({ error: "empty_update" });
    const assignments = columns.map((column, index) => `${column} = $${index + 2}`);
    if (["brands", "articles"].includes(resource.table)) assignments.push("updated_at = now()");
    const result = await database.query(`UPDATE ${resource.table} SET ${assignments.join(", ")} WHERE id = $1 RETURNING *`, [request.params.id, ...values]);
    if (!result.rows[0]) return reply.code(404).send({ error: `${resource.path}_not_found` });
    return { data: result.rows[0] };
  });

  app.delete<{ Params: Params }>(`${base}/:id`, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const result = await database.query(`DELETE FROM ${resource.table} WHERE id = $1 RETURNING id`, [request.params.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: `${resource.path}_not_found` });
    return reply.code(204).send();
  });
}

function registerProducts(app: FastifyInstance, database: Database, requireAdmin: Authenticator) {
  const base = "/v1/admin/products";
  app.get<{ Querystring: ListQuery }>(base, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const { limit, offset } = pagination(request.query);
    const values: unknown[] = []; const clauses: string[] = [];
    for (const [queryKey, column] of [["status", "p.status"], ["lineId", "p.line_id"], ["brandId", "l.brand_id"]] as const) {
      const value = request.query[queryKey]; if (value) { values.push(value); clauses.push(`${column} = $${values.length}`); }
    }
    values.push(limit, offset);
    const result = await database.query(
      `SELECT p.*, COALESCE(json_agg(json_build_object('tagId', pt.tag_id, 'weight', pt.weight)) FILTER (WHERE pt.tag_id IS NOT NULL), '[]') AS tags
         FROM tobacco_products p JOIN tobacco_lines l ON l.id = p.line_id LEFT JOIN tobacco_product_tags pt ON pt.product_id = p.id
         ${clauses.length ? `WHERE ${clauses.join(" AND ")}` : ""} GROUP BY p.id ORDER BY p.name LIMIT $${values.length - 1} OFFSET $${values.length}`, values);
    return { data: result.rows, pagination: { limit, offset } };
  });
  app.get<{ Params: Params }>(`${base}/:id`, async (request, reply) => adminProductDetail(database, requireAdmin, request, reply));
  app.post<{ Body: Body }>(base, async (request, reply) => writeProduct(database, requireAdmin, request, reply, null));
  app.put<{ Params: Params; Body: Body }>(`${base}/:id`, async (request, reply) => writeProduct(database, requireAdmin, request, reply, request.params.id));
  app.delete<{ Params: Params }>(`${base}/:id`, async (request, reply) => deleteById(database, requireAdmin, request, reply, "tobacco_products", "product_not_found"));
}

async function adminProductDetail(database: Database, requireAdmin: Authenticator, request: FastifyRequest<{ Params: Params }>, reply: FastifyReply) {
  if (!(await requireAdmin(request, reply))) return;
  const result = await database.query(
    `SELECT p.*, COALESCE(json_agg(json_build_object('tagId', pt.tag_id, 'weight', pt.weight)) FILTER (WHERE pt.tag_id IS NOT NULL), '[]') AS tags
       FROM tobacco_products p LEFT JOIN tobacco_product_tags pt ON pt.product_id = p.id WHERE p.id = $1 GROUP BY p.id`, [request.params.id]);
  if (!result.rows[0]) return reply.code(404).send({ error: "product_not_found" });
  return { data: result.rows[0] };
}

async function writeProduct(database: Database, requireAdmin: Authenticator, request: FastifyRequest<{ Body: Body }>, reply: FastifyReply, id: string | null) {
  if (!(await requireAdmin(request, reply))) return;
  const fields = { lineId: "line_id", slug: "slug", name: "name",nameRu:"name_ru",nameEn:"name_en",descriptionRu:"description_ru",descriptionEn:"description_en",translationOrigin:"translation_origin",sourceConfidence:"source_confidence", sweetness: "sweetness", acidity: "acidity", freshness: "freshness", status: "status", sourceId: "source_id", verifiedAt: "verified_at" };
  const resource: SimpleResource = { path: "products", table: "tobacco_products", fields, required: ["lineId", "slug", "name","nameRu","nameEn", "sweetness", "acidity", "freshness"],localized:["nameRu","nameEn"], provenance: true };
  const error = validateResource(request.body, resource, !id);
  if (error || !Array.isArray(request.body.tags)) return reply.code(400).send({ error: error ?? "tags_required" });
  const tags = request.body.tags as Array<{ tagId?: string; weight?: number }>;
  if (tags.some(tag => !tag.tagId || !Number.isInteger(tag.weight ?? 1) || (tag.weight ?? 1) < 1 || (tag.weight ?? 1) > 5)) return reply.code(400).send({ error: "invalid_tags" });
  return transactionalAggregate(database, reply, async client => {
    const mapped = mappedValues(request.body, fields); let productId = id;
    if (id) {
      const assignments = mapped.columns.map((column, index) => `${column} = $${index + 2}`);
      const updated = await client.query(`UPDATE tobacco_products SET ${assignments.join(", ")} WHERE id = $1 RETURNING id`, [id, ...mapped.values]);
      if (!updated.rows[0]) return null;
      await client.query("DELETE FROM tobacco_product_tags WHERE product_id = $1", [id]);
    } else {
      const inserted = await client.query(`INSERT INTO tobacco_products (${mapped.columns.join(",")}) VALUES (${mapped.values.map((_, i) => `$${i + 1}`).join(",")}) RETURNING id`, mapped.values);
      productId = inserted.rows[0]!.id;
    }
    for (const tag of tags) await client.query("INSERT INTO tobacco_product_tags(product_id, tag_id, weight) VALUES ($1,$2,$3)", [productId, tag.tagId, tag.weight ?? 1]);
    return { id: productId };
  });
}

function registerOfficialMixes(app: FastifyInstance, database: Database, requireAdmin: Authenticator) {
  const base = "/v1/admin/official-mixes";
  app.get<{ Querystring: ListQuery }>(base, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const { limit, offset } = pagination(request.query); const values: unknown[] = [];
    const where = request.query.status ? (values.push(request.query.status), "WHERE status = $1") : "";
    values.push(limit, offset);
    const result = await database.query(`SELECT * FROM official_mixes ${where} ORDER BY updated_at DESC LIMIT $${values.length - 1} OFFSET $${values.length}`, values);
    return { data: result.rows, pagination: { limit, offset } };
  });
  app.get<{ Params: Params }>(`${base}/:id`, async (request, reply) => {
    if (!(await requireAdmin(request, reply))) return;
    const result = await database.query(`SELECT m.*, COALESCE(json_agg(json_build_object('productId', c.product_id, 'percentage', c.percentage, 'position', c.position) ORDER BY c.position) FILTER (WHERE c.product_id IS NOT NULL), '[]') AS components FROM official_mixes m LEFT JOIN official_mix_components c ON c.mix_id=m.id WHERE m.id=$1 GROUP BY m.id`, [request.params.id]);
    if (!result.rows[0]) return reply.code(404).send({ error: "official_mix_not_found" }); return { data: result.rows[0] };
  });
  app.post<{ Body: Body }>(base, async (request, reply) => writeOfficialMix(database, requireAdmin, request, reply, null));
  app.put<{ Params: Params; Body: Body }>(`${base}/:id`, async (request, reply) => writeOfficialMix(database, requireAdmin, request, reply, request.params.id));
  app.delete<{ Params: Params }>(`${base}/:id`, async (request, reply) => deleteById(database, requireAdmin, request, reply, "official_mixes", "official_mix_not_found"));
}

async function writeOfficialMix(database: Database, requireAdmin: Authenticator, request: FastifyRequest<{ Body: Body }>, reply: FastifyReply, id: string | null) {
  if (!(await requireAdmin(request, reply))) return;
  const fields = { slug: "slug", titleRu: "title_ru", titleEn: "title_en",summaryRu:"summary_ru",summaryEn:"summary_en",translationOrigin:"translation_origin",sourceConfidence:"source_confidence", status: "status", sourceId: "source_id", verifiedAt: "verified_at", publishedAt: "published_at" };
  const resource: SimpleResource = { path: "official-mixes", table: "official_mixes", fields, required: ["slug", "titleRu", "titleEn"], localized: ["titleRu", "titleEn"], provenance: true };
  const error = validateResource(request.body, resource, !id); const components = request.body.components as Array<{ productId?: string; percentage?: number }>;
  if (error) return reply.code(400).send({ error });
  if (!Array.isArray(components) || !components.length || components.some(c => !c.productId || !Number.isInteger(c.percentage) || c.percentage! < 1) || components.reduce((s,c) => s + (c.percentage ?? 0), 0) !== 100) return reply.code(400).send({ error: "mix_percentages_must_total_100" });
  return transactionalAggregate(database, reply, async client => {
    const mapped = mappedValues(request.body, fields); let mixId = id;
    if (id) {
      const updated = await client.query(`UPDATE official_mixes SET ${mapped.columns.map((c,i)=>`${c}=$${i+2}`).join(",")}, updated_at=now() WHERE id=$1 RETURNING id`, [id,...mapped.values]);
      if (!updated.rows[0]) return null; await client.query("DELETE FROM official_mix_components WHERE mix_id=$1",[id]);
    } else {
      const inserted = await client.query(`INSERT INTO official_mixes (${mapped.columns.join(",")}) VALUES (${mapped.values.map((_,i)=>`$${i+1}`).join(",")}) RETURNING id`,mapped.values); mixId=inserted.rows[0]!.id;
    }
    for (const [index,c] of components.entries()) await client.query("INSERT INTO official_mix_components(mix_id,product_id,percentage,position) VALUES ($1,$2,$3,$4)",[mixId,c.productId,c.percentage,index+1]);
    return { id: mixId };
  });
}

function registerDenyRules(app: FastifyInstance, database: Database, requireAdmin: Authenticator) {
  const base = "/v1/admin/substitution-deny-rules";
  app.get(base, async (request, reply) => { if (!(await requireAdmin(request,reply))) return; return { data: (await database.query("SELECT * FROM substitution_deny_rules ORDER BY created_at DESC")).rows }; });
  app.post<{ Body: Body }>(base, async (request, reply) => {
    if (!(await requireAdmin(request,reply))) return; const { sourceProductId, substituteProductId, reason } = request.body;
    if (!sourceProductId || !substituteProductId || sourceProductId === substituteProductId) return reply.code(400).send({error:"invalid_deny_rule"});
    const result=await database.query("INSERT INTO substitution_deny_rules(source_product_id,substitute_product_id,reason) VALUES($1,$2,$3) RETURNING *",[sourceProductId,substituteProductId,reason??null]); return reply.code(201).send({data:result.rows[0]});
  });
  app.put<{ Body: Body }>(base, async (request, reply) => {
    if (!(await requireAdmin(request,reply))) return; const { sourceProductId, substituteProductId, reason }=request.body;
    if (!sourceProductId || !substituteProductId) return reply.code(400).send({error:"invalid_deny_rule"});
    const result=await database.query("UPDATE substitution_deny_rules SET reason=$3 WHERE source_product_id=$1 AND substitute_product_id=$2 RETURNING *",[sourceProductId,substituteProductId,reason??null]); if(!result.rows[0]) return reply.code(404).send({error:"deny_rule_not_found"}); return {data:result.rows[0]};
  });
  app.delete<{ Body: Body }>(base, async (request, reply) => {
    if (!(await requireAdmin(request,reply))) return; const { sourceProductId, substituteProductId }=request.body;
    const result=await database.query("DELETE FROM substitution_deny_rules WHERE source_product_id=$1 AND substitute_product_id=$2 RETURNING source_product_id",[sourceProductId,substituteProductId]); if(!result.rows[0]) return reply.code(404).send({error:"deny_rule_not_found"}); return reply.code(204).send();
  });
}

function validateResource(body: Body, resource: SimpleResource, creating: boolean): string | null {
  if (!body || typeof body !== "object") return "invalid_body";
  if (creating && resource.required.some(key => body[key] == null || body[key] === "")) return "required_fields_missing";
  if (resource.localized?.some(key => key in body && (typeof body[key] !== "string" || !(body[key] as string).trim()))) return "localized_fields_required";
  if (resource.provenance && body.status != null && !["draft","published","archived"].includes(String(body.status))) return "invalid_status";
  if (resource.provenance && body.status !== undefined && body.status !== "draft" && (!body.sourceId || !body.verifiedAt)) return "published_content_requires_provenance";
  return null;
}

function mappedValues(body: Body, fields: Record<string,string>) { const entries=Object.entries(fields).filter(([key])=>key in body); return {columns:entries.map(([,column])=>column),values:entries.map(([key])=>body[key])}; }
function pagination(query: ListQuery) { const requested=Number(query.limit??50); return {limit:Number.isInteger(requested)?Math.min(Math.max(requested,1),100):50,offset:Math.max(Number(query.offset??0)||0,0)}; }

async function deleteById(database: Database, requireAdmin: Authenticator, request: FastifyRequest<{Params:Params}>, reply: FastifyReply, table:string,error:string) { if(!(await requireAdmin(request,reply)))return; const result=await database.query(`DELETE FROM ${table} WHERE id=$1 RETURNING id`,[request.params.id]); if(!result.rows[0])return reply.code(404).send({error}); return reply.code(204).send(); }

async function transactionalAggregate(database: Database, reply: FastifyReply, operation:(client:any)=>Promise<unknown>) {
  if(!database.connect) throw new Error("Database transactions are unavailable"); const client=await database.connect();
  try { await client.query("BEGIN"); const data=await operation(client); if(!data){await client.query("ROLLBACK");return reply.code(404).send({error:"not_found"});} await client.query("COMMIT"); return reply.send({data}); }
  catch(error){await client.query("ROLLBACK");throw error;} finally{client.release();}
}
