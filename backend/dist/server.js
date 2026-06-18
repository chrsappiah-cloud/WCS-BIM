import "dotenv/config";
import express from "express";
import multer from "multer";
import { Pool } from "pg";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { jwtVerify } from "jose";
import { randomUUID } from "node:crypto";
import { LLMClient } from "./llmClient.js";
import { isSupabaseAuthConfigured, userIDForAccessToken } from "./supabaseAuth.js";
import { optimizeMix } from "./services/optimizer.service.js";
import { checkDrift, retrainingStatus, runRetraining, startRetrainingScheduler } from "./services/retraining.service.js";
export const app = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const llm = new LLMClient();
const mlURL = process.env.ML_SERVICE_URL ?? "http://127.0.0.1:8000";
const startedAt = Date.now();
let requestCount = 0;
const allowedUploadBuckets = new Set([
    "project-files", "material-tests", "bim-files", "site-images", "reports",
]);
const allowedMimeTypes = new Set([
    "application/pdf",
    "application/octet-stream",
    "application/zip",
    "image/heic",
    "image/jpeg",
    "image/png",
    "model/gltf-binary",
    "model/gltf+json",
    "text/csv",
]);
const maxUploadBytes = Number(process.env.MAX_UPLOAD_BYTES ?? 20 * 1024 * 1024);
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: maxUploadBytes, files: 1 } });
const rolePermissions = {
    admin: ["view_projects", "edit_projects", "upload_tests", "predict_materials", "optimize_mixes", "manage_models", "view_reports", "retrain_models"],
    project_manager: ["view_projects", "edit_projects", "upload_tests", "predict_materials", "optimize_mixes", "view_reports"],
    lab_technician: ["view_projects", "upload_tests", "predict_materials", "view_reports"],
    model_maintainer: ["view_projects", "predict_materials", "optimize_mixes", "manage_models", "view_reports", "retrain_models"],
    viewer: ["view_projects", "view_reports"],
};
const permissionsForUser = async (userId) => {
    if (typeof userId !== "string" || !userId) {
        return { role: "admin", permissions: [...rolePermissions.admin], organizationId: null };
    }
    const { rows } = await pool.query(`select organization_id, role from org_members where user_id=$1
     order by case role when 'admin' then 0 when 'model_maintainer' then 1 else 2 end limit 1`, [userId]);
    const role = (rows[0]?.role ?? "viewer");
    return { role, permissions: [...rolePermissions[role]], organizationId: rows[0]?.organization_id ?? null };
};
const camelCase = (key) => key.replace(/_([a-z])/g, (_match, letter) => letter.toUpperCase());
const toCamelCase = (value) => {
    if (Array.isArray(value))
        return value.map(toCamelCase);
    if (value && typeof value === "object") {
        return Object.fromEntries(Object.entries(value)
            .map(([key, nestedValue]) => [camelCase(key), toCamelCase(nestedValue)]));
    }
    return value;
};
const storageClient = () => {
    const url = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !serviceRoleKey) {
        throw new Error("Supabase storage is not configured.");
    }
    return createClient(url, serviceRoleKey, {
        auth: { autoRefreshToken: false, persistSession: false },
    });
};
class UploadAccessError extends Error {
}
const requireProjectUploadAccess = async (projectId, userId) => {
    if (typeof userId !== "string" || !userId) {
        throw new UploadAccessError("Authenticated project membership is required.");
    }
    const { rowCount } = await pool.query(`select 1 from projects p
     join org_members om on om.organization_id=p.organization_id
     where p.id=$1 and om.user_id=$2
       and om.role in ('admin','project_manager','lab_technician')
     union all
     select 1 from project_members
     where project_id=$1 and user_id=$2
       and role in ('admin','project_member','lab_technician')
     limit 1`, [projectId, userId]);
    if (!rowCount) {
        throw new UploadAccessError("The user cannot access files for this project.");
    }
};
const requireModelMaintainerAccess = async (userId) => {
    if (!isSupabaseAuthConfigured() && !process.env.JWT_SECRET)
        return;
    if (typeof userId !== "string" || !userId) {
        throw new UploadAccessError("Authenticated model-maintainer access is required.");
    }
    const { rowCount } = await pool.query(`select 1 from org_members
     where user_id=$1 and role in ('admin','model_maintainer')
     limit 1`, [userId]);
    if (!rowCount) {
        throw new UploadAccessError("Admin or model-maintainer access is required.");
    }
};
app.use(express.json({ limit: "5mb" }));
app.use((_req, _res, next) => {
    requestCount += 1;
    next();
});
app.get("/health", (_req, res) => res.json({ status: "ok" }));
app.get("/metrics", (_req, res) => res.json({
    requests: requestCount,
    uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
}));
app.use(async (req, res, next) => {
    const supabaseConfigured = isSupabaseAuthConfigured();
    const secret = process.env.JWT_SECRET;
    const token = req.header("authorization")?.replace(/^Bearer\s+/i, "");
    if (!supabaseConfigured && !secret)
        return next();
    if (!token)
        return res.status(401).json({ error: "Bearer token required." });
    if (supabaseConfigured) {
        try {
            res.locals.userId = await userIDForAccessToken(token);
            return next();
        }
        catch {
            // Allow the local JWT fallback below when both auth modes are configured.
        }
    }
    if (secret) {
        try {
            const { payload } = await jwtVerify(token, new TextEncoder().encode(secret));
            res.locals.userId = payload.sub;
            return next();
        }
        catch {
            // Return the shared authentication error below.
        }
    }
    return res.status(401).json({ error: "Invalid or expired bearer token." });
});
app.get("/api/session/permissions", async (_req, res) => {
    res.json(await permissionsForUser(res.locals.userId));
});
app.get("/api/dashboard", async (_req, res) => {
    const access = await permissionsForUser(res.locals.userId);
    const organizationId = access.organizationId;
    const values = organizationId ? [organizationId] : [];
    const orgFilter = organizationId ? " where organization_id=$1" : "";
    const projectFilter = organizationId ? " where project_id in (select id from projects where organization_id=$1)" : "";
    const [projects, materials, tests, reports, models] = await Promise.all([
        pool.query(`select count(*)::int as count from projects${orgFilter}`, values),
        pool.query(`select count(*)::int as count from materials${orgFilter}`, values),
        pool.query(`select count(*)::int as count from material_tests${orgFilter}`, values),
        pool.query(`select count(*)::int as count from ai_reports${projectFilter}`, values),
        pool.query(`select count(*)::int as count from model_registry${organizationId ? " where organization_id=$1 and active=true" : " where active=true"}`, values),
    ]);
    const recentTests = await pool.query(`select id,test_type,status,created_at from material_tests${orgFilter} order by created_at desc limit 5`, values);
    res.json({
        role: access.role,
        permissions: access.permissions,
        organizationId,
        counts: {
            projects: projects.rows[0].count,
            materials: materials.rows[0].count,
            tests: tests.rows[0].count,
            reports: reports.rows[0].count,
            activeModels: models.rows[0].count,
        },
        recentTests: toCamelCase(recentTests.rows),
    });
});
app.get(["/projects", "/api/projects"], async (_req, res) => {
    const { rows } = await pool.query("select id, name, location, status, created_at as \"createdAt\" from projects order by created_at desc");
    res.json(rows);
});
app.post(["/projects", "/api/projects"], async (req, res) => {
    const body = z.object({
        name: z.string().min(1),
        description: z.string().optional(),
        location: z.string().optional(),
        clientName: z.string().optional(),
        status: z.enum(["active", "completed", "paused"]).default("active"),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into projects(name,description,location,client_name,status)
     values($1,$2,$3,$4,$5) returning *`, [body.name, body.description, body.location, body.clientName, body.status]);
    res.status(201).json(toCamelCase(rows[0]));
});
app.get(["/projects/:projectId", "/api/projects/:projectId"], async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from projects where id=$1", [projectId]);
    if (!rows[0])
        return res.status(404).json({ error: "Project not found." });
    res.json(toCamelCase(rows[0]));
});
app.patch(["/projects/:projectId", "/api/projects/:projectId"], async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        name: z.string().trim().min(1).optional(),
        description: z.string().nullable().optional(),
        location: z.string().nullable().optional(),
        clientName: z.string().nullable().optional(),
        status: z.enum(["active", "completed", "paused"]).optional(),
    }).parse(req.body);
    const { rows } = await pool.query(`update projects set
      name=coalesce($2,name),
      description=case when $3::boolean then $4 else description end,
      location=case when $5::boolean then $6 else location end,
      client_name=case when $7::boolean then $8 else client_name end,
      status=coalesce($9,status)
     where id=$1 returning *`, [projectId, body.name, "description" in body, body.description,
        "location" in body, body.location, "clientName" in body, body.clientName, body.status]);
    if (!rows[0])
        return res.status(404).json({ error: "Project not found." });
    res.json(toCamelCase(rows[0]));
});
const materialCategory = z.enum([
    "concrete", "geopolymer", "asphalt", "soil",
    "steel", "FRP", "smart_glass", "smart_brick",
]);
const uuidList = z.array(z.string().uuid()).default([]);
const concreteMix = z.object({
    name: z.string().min(1),
    binderType: z.string().default("OPC"),
    cementKg: z.number().nonnegative().default(0),
    flyAshKg: z.number().nonnegative().default(0),
    ggbssKg: z.number().nonnegative().default(0),
    silicaFumeKg: z.number().nonnegative().default(0),
    waterKg: z.number().nonnegative().default(0),
    superplasticizerKg: z.number().nonnegative().default(0),
    fineAggregateKg: z.number().nonnegative().default(0),
    coarseAggregateKg: z.number().nonnegative().default(0),
    ageDays: z.number().int().positive().default(28),
});
app.get("/projects/:projectId/concrete-mixes", async (req, res) => {
    const { rows } = await pool.query("select * from concrete_mixes where project_id=$1 order by created_at desc", [req.params.projectId]);
    res.json(toCamelCase(rows));
});
app.post("/projects/:projectId/concrete-mixes", async (req, res) => {
    const body = concreteMix.parse(req.body);
    const binder = body.cementKg + body.flyAshKg + body.ggbssKg + body.silicaFumeKg;
    const { rows } = await pool.query(`insert into concrete_mixes(
      project_id,name,binder_type,cement_kg,fly_ash_kg,ggbss_kg,silica_fume_kg,water_kg,
      superplasticizer_kg,fine_aggregate_kg,coarse_aggregate_kg,w_b_ratio,scm_ratio,sp_ratio,age_days
    ) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) returning *`, [req.params.projectId, body.name, body.binderType, body.cementKg, body.flyAshKg, body.ggbssKg,
        body.silicaFumeKg, body.waterKg, body.superplasticizerKg, body.fineAggregateKg,
        body.coarseAggregateKg, binder ? body.waterKg / binder : null,
        binder ? (body.flyAshKg + body.ggbssKg + body.silicaFumeKg) / binder : null,
        binder ? body.superplasticizerKg / binder : null, body.ageDays]);
    res.status(201).json(toCamelCase(rows[0]));
});
for (const [path, table] of [
    ["materials", "materials"],
    ["tests", "material_tests"],
    ["design-alternatives", "design_alternatives"],
    ["fabrication-modules", "fabrication_modules"],
]) {
    app.get(`/projects/:projectId/${path}`, async (req, res) => {
        const { rows } = await pool.query(`select * from ${table} where project_id=$1 order by created_at desc`, [req.params.projectId]);
        res.json(toCamelCase(rows));
    });
}
app.get("/api/materials", async (req, res) => {
    const query = z.object({ projectId: z.string().uuid() }).parse(req.query);
    const { rows } = await pool.query("select * from materials where project_id=$1 order by created_at desc", [query.projectId]);
    res.json({ items: toCamelCase(rows) });
});
app.get("/api/projects/:projectId/materials", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from materials where project_id=$1 order by created_at desc", [projectId]);
    res.json(toCamelCase(rows));
});
app.post("/api/projects/:projectId/materials", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        name: z.string().trim().min(1),
        category: materialCategory,
        spec: z.record(z.string()).default({}),
        supplier: z.string().optional(),
        unitCost: z.number().nonnegative().optional(),
        co2Factor: z.number().nonnegative().optional(),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into materials(project_id,name,category,spec,supplier,unit_cost,co2_factor)
     values($1,$2,$3,$4,$5,$6,$7) returning *`, [projectId, body.name, body.category, JSON.stringify(body.spec), body.supplier, body.unitCost, body.co2Factor]);
    res.status(201).json(toCamelCase(rows[0]));
});
app.get("/api/tests", async (req, res) => {
    const query = z.object({ projectId: z.string().uuid() }).parse(req.query);
    const { rows } = await pool.query("select * from material_tests where project_id=$1 order by created_at desc", [query.projectId]);
    res.json({ items: toCamelCase(rows) });
});
app.post("/api/tests", async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        materialId: z.string().uuid().optional(),
        bimElementId: z.string().uuid().optional(),
        testType: z.string().trim().min(1),
        ageDays: z.number().int().positive().optional(),
        inputFeatures: z.record(z.number()).default({}),
        measuredValues: z.record(z.number()).default({}),
        predictedValues: z.record(z.number()).default({}),
        modelName: z.string().optional(),
        confidence: z.number().min(0).max(1).optional(),
        status: z.string().default("pending"),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into material_tests(
      project_id,material_id,bim_element_id,test_type,age_days,input_features,
      measured_values,predicted_values,ai_model,model_name,confidence,status
    ) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$9,$10,$11) returning *`, [body.projectId, body.materialId, body.bimElementId, body.testType, body.ageDays,
        JSON.stringify(body.inputFeatures), JSON.stringify(body.measuredValues),
        JSON.stringify(body.predictedValues), body.modelName, body.confidence, body.status]);
    res.status(201).json({ ok: true, test: toCamelCase(rows[0]) });
});
app.get("/api/projects/:projectId/tests", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from material_tests where project_id=$1 order by created_at desc", [projectId]);
    res.json(toCamelCase(rows));
});
app.post("/api/projects/:projectId/tests", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        materialId: z.string().uuid().optional(),
        bimElementId: z.string().uuid().optional(),
        testType: z.string().trim().min(1),
        ageDays: z.number().int().positive().optional(),
        inputFeatures: z.record(z.number()).default({}),
        measuredValues: z.record(z.number()).default({}),
        predictedValues: z.record(z.number()).default({}),
        modelName: z.string().optional(),
        confidence: z.number().min(0).max(1).optional(),
        status: z.string().default("pending"),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into material_tests(
      project_id,material_id,bim_element_id,test_type,age_days,input_features,
      measured_values,predicted_values,ai_model,model_name,confidence,status
    ) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$9,$10,$11) returning *`, [projectId, body.materialId, body.bimElementId, body.testType, body.ageDays,
        JSON.stringify(body.inputFeatures), JSON.stringify(body.measuredValues),
        JSON.stringify(body.predictedValues), body.modelName, body.confidence, body.status]);
    res.status(201).json(toCamelCase(rows[0]));
});
app.get("/api/bim/elements", async (req, res) => {
    const query = z.object({ projectId: z.string().uuid() }).parse(req.query);
    const { rows } = await pool.query("select * from bim_elements where project_id=$1 order by created_at desc", [query.projectId]);
    res.json({ items: toCamelCase(rows) });
});
app.get("/api/projects/:projectId/bim-elements", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from bim_elements where project_id=$1 order by created_at desc", [projectId]);
    res.json(toCamelCase(rows));
});
app.post("/api/projects/:projectId/bim-elements", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        externalId: z.string().optional(),
        elementType: z.string().trim().min(1),
        name: z.string().optional(),
        levelName: z.string().optional(),
        metadata: z.record(z.union([z.string(), z.number(), z.boolean()])).default({}),
        dimensions: z.record(z.number()).default({}),
        quantity: z.number().nonnegative().default(1),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into bim_elements(
      project_id,external_guid,external_id,element_type,name,level_name,metadata,dimensions,quantity
    ) values($1,$2,$2,$3,$4,$5,$6,$7,$8) returning *`, [projectId, body.externalId, body.elementType, body.name, body.levelName,
        JSON.stringify(body.metadata), JSON.stringify(body.dimensions), body.quantity]);
    res.status(201).json(toCamelCase(rows[0]));
});
app.post("/api/bim/link-test", async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        testId: z.string().uuid(),
        bimElementId: z.string().uuid(),
    }).parse(req.body);
    const { rows } = await pool.query(`update material_tests set bim_element_id=$3
     where project_id=$1 and id=$2
     and exists(select 1 from bim_elements where project_id=$1 and id=$3)
     returning *`, [body.projectId, body.testId, body.bimElementId]);
    if (!rows[0])
        return res.status(404).json({ error: "Project-scoped test or BIM element not found." });
    res.json({ ok: true, linked: toCamelCase(rows[0]) });
});
app.post("/api/bim/fabrication-plan", async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        bimElementId: z.string().uuid().optional(),
        moduleName: z.string().trim().min(1),
        processType: z.string().trim().optional(),
        estimatedTimeHours: z.number().nonnegative().optional(),
        wastePercent: z.number().min(0).max(100).optional(),
        qaCheckpoints: z.array(z.string()).default([]),
        risks: z.array(z.string()).default([]),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into fabrication_plans(
      project_id,bim_element_id,module_name,process_type,estimated_time_hours,
      waste_percent,qa_checkpoints,risks
    ) select $1,$2,$3,$4,$5,$6,$7,$8
      where $2::uuid is null
      or exists(select 1 from bim_elements where project_id=$1 and id=$2)
      returning *`, [body.projectId, body.bimElementId, body.moduleName, body.processType, body.estimatedTimeHours,
        body.wastePercent, JSON.stringify(body.qaCheckpoints), JSON.stringify(body.risks)]);
    if (!rows[0])
        return res.status(404).json({ error: "Project-scoped BIM element not found." });
    res.status(201).json({ ok: true, plan: toCamelCase(rows[0]) });
});
app.get("/api/projects/:projectId/reports", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from ai_reports where project_id=$1 order by created_at desc", [projectId]);
    res.json(toCamelCase(rows));
});
app.get("/api/projects/:projectId/fabrication-plans", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const { rows } = await pool.query("select * from fabrication_plans where project_id=$1 order by created_at desc", [projectId]);
    res.json(toCamelCase(rows));
});
app.post("/api/projects/:projectId/fabrication-plans", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        bimElementId: z.string().uuid().optional(),
        moduleName: z.string().trim().min(1),
        processType: z.string().trim().optional(),
        estimatedTimeHours: z.number().nonnegative().optional(),
        wastePercent: z.number().min(0).max(100).optional(),
        qaCheckpoints: z.array(z.string()).default([]),
        risks: z.array(z.string()).default([]),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into fabrication_plans(
      project_id,bim_element_id,module_name,process_type,estimated_time_hours,
      waste_percent,qa_checkpoints,risks
    ) values($1,$2,$3,$4,$5,$6,$7,$8) returning *`, [projectId, body.bimElementId, body.moduleName, body.processType, body.estimatedTimeHours,
        body.wastePercent, JSON.stringify(body.qaCheckpoints), JSON.stringify(body.risks)]);
    res.status(201).json(toCamelCase(rows[0]));
});
const modelRegistryInput = z.object({
    modelName: z.string().trim().min(1),
    version: z.string().trim().min(1),
    task: z.string().trim().min(1),
    featureSet: z.array(z.string()).default([]),
    metrics: z.record(z.unknown()).default({}),
    artifactPath: z.string().trim().min(1).nullable().optional(),
    trainedAt: z.string().datetime().optional(),
    active: z.boolean().default(false),
    notes: z.string().nullable().optional(),
});
app.get(["/api/model-registry", "/api/models"], async (req, res) => {
    const query = z.object({
        task: z.string().optional(),
        active: z.enum(["true", "false"]).optional(),
    }).parse(req.query);
    const conditions = [];
    const values = [];
    if (query.task) {
        values.push(query.task);
        conditions.push(`task=$${values.length}`);
    }
    if (query.active) {
        values.push(query.active === "true");
        conditions.push(`active=$${values.length}`);
    }
    const where = conditions.length ? `where ${conditions.join(" and ")}` : "";
    const { rows } = await pool.query(`select * from model_registry ${where} order by trained_at desc`, values);
    res.json(toCamelCase(rows));
});
app.get(["/api/model-registry/:id", "/api/models/:id"], async (req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    const id = z.string().uuid().parse(req.params.id);
    const { rows } = await pool.query("select * from model_registry where id=$1", [id]);
    if (!rows[0])
        return res.status(404).json({ error: "Model registry entry not found." });
    res.json(toCamelCase(rows[0]));
});
app.post(["/api/model-registry", "/api/models"], async (req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    const body = modelRegistryInput.parse(req.body);
    const client = await pool.connect();
    try {
        await client.query("begin");
        if (body.active) {
            await client.query("update model_registry set active=false where task=$1", [body.task]);
        }
        const { rows } = await client.query(`insert into model_registry(model_name,version,task,feature_set,metrics,artifact_path,trained_at,active,notes)
       values($1,$2,$3,$4,$5,$6,coalesce($7,now()),$8,$9) returning *`, [body.modelName, body.version, body.task, JSON.stringify(body.featureSet),
            JSON.stringify(body.metrics), body.artifactPath, body.trainedAt, body.active, body.notes]);
        await client.query("commit");
        res.status(201).json(toCamelCase(rows[0]));
    }
    catch (error) {
        await client.query("rollback");
        throw error;
    }
    finally {
        client.release();
    }
});
app.patch(["/api/model-registry/:id", "/api/models/:id"], async (req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    const id = z.string().uuid().parse(req.params.id);
    const updates = modelRegistryInput.partial().parse(req.body);
    const client = await pool.connect();
    try {
        await client.query("begin");
        const current = await client.query("select * from model_registry where id=$1 for update", [id]);
        if (!current.rows[0]) {
            await client.query("rollback");
            return res.status(404).json({ error: "Model registry entry not found." });
        }
        const existing = current.rows[0];
        const task = updates.task ?? existing.task;
        const active = updates.active ?? existing.active;
        if (active) {
            await client.query("update model_registry set active=false where task=$1 and id<>$2", [task, id]);
        }
        const { rows } = await client.query(`update model_registry set model_name=$2,version=$3,task=$4,feature_set=$5,metrics=$6,
       artifact_path=$7,trained_at=$8,active=$9,notes=$10 where id=$1 returning *`, [id, updates.modelName ?? existing.model_name, updates.version ?? existing.version, task,
            JSON.stringify(updates.featureSet ?? existing.feature_set),
            JSON.stringify(updates.metrics ?? existing.metrics),
            updates.artifactPath === undefined ? existing.artifact_path : updates.artifactPath,
            updates.trainedAt ?? existing.trained_at, active,
            updates.notes === undefined ? existing.notes : updates.notes]);
        await client.query("commit");
        res.json(toCamelCase(rows[0]));
    }
    catch (error) {
        await client.query("rollback");
        throw error;
    }
    finally {
        client.release();
    }
});
app.post(["/api/model-registry/:id/activate", "/api/models/:id/activate"], async (req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    const id = z.string().uuid().parse(req.params.id);
    const client = await pool.connect();
    try {
        await client.query("begin");
        const current = await client.query("select task from model_registry where id=$1 for update", [id]);
        if (!current.rows[0]) {
            await client.query("rollback");
            return res.status(404).json({ error: "Model registry entry not found." });
        }
        const task = current.rows[0].task;
        await client.query("update model_registry set active=false where task=$1", [task]);
        const { rows } = await client.query("update model_registry set active=true where id=$1 returning *", [id]);
        await client.query("commit");
        res.json(toCamelCase(rows[0]));
    }
    catch (error) {
        await client.query("rollback");
        throw error;
    }
    finally {
        client.release();
    }
});
app.delete(["/api/model-registry/:id", "/api/models/:id"], async (req, res) => {
    const id = z.string().uuid().parse(req.params.id);
    const { rowCount } = await pool.query("delete from model_registry where id=$1", [id]);
    if (!rowCount)
        return res.status(404).json({ error: "Model registry entry not found." });
    res.status(204).send();
});
app.get("/api/retrain/status", async (_req, res) => {
    res.json(await retrainingStatus());
});
app.post("/api/retrain/run", async (_req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    res.status(202).json(await runRetraining());
});
app.post("/api/retrain/drift-check", async (req, res) => {
    await requireModelMaintainerAccess(res.locals.userId);
    res.json(await checkDrift(req.body));
});
app.post("/api/materials", async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        name: z.string().trim().min(1),
        category: materialCategory,
        spec: z.record(z.string()).default({}),
    }).parse(req.body);
    const { rows } = await pool.query(`insert into materials(project_id,name,category,spec)
     values($1,$2,$3,$4) returning id, project_id as "projectId", name, category, spec`, [body.projectId, body.name, body.category, body.spec]);
    res.status(201).json(rows[0]);
});
app.post("/api/projects/:projectId/bim-link", async (req, res) => {
    const projectId = z.string().uuid().parse(req.params.projectId);
    const body = z.object({
        materialId: z.string().uuid(),
        bimElementIds: uuidList,
        testIds: uuidList,
    }).parse(req.body);
    const client = await pool.connect();
    try {
        await client.query("begin");
        const elements = body.bimElementIds.length
            ? await client.query("update bim_elements set material_id=$1 where project_id=$2 and id=any($3::uuid[])", [body.materialId, projectId, body.bimElementIds])
            : { rowCount: 0 };
        const tests = body.testIds.length
            ? await client.query(`update material_tests set material_id=$1,
         bim_element_id=coalesce(bim_element_id,$4::uuid)
         where project_id=$2 and id=any($3::uuid[])`, [body.materialId, projectId, body.testIds, body.bimElementIds[0] ?? null])
            : { rowCount: 0 };
        await client.query("commit");
        res.json({
            projectId,
            materialId: body.materialId,
            linkedElements: elements.rowCount ?? 0,
            linkedTests: tests.rowCount ?? 0,
        });
    }
    catch (error) {
        await client.query("rollback");
        throw error;
    }
    finally {
        client.release();
    }
});
const proxyJSON = async (url, body) => {
    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
    const text = await response.text();
    if (!response.ok) {
        throw new Error(`ML service error ${response.status}: ${text}`);
    }
    return JSON.parse(text);
};
app.post("/ai/mix-optimizer", async (req, res) => {
    res.json(await optimizeMix(req.body));
});
app.get("/ai/models", async (_req, res) => {
    const response = await fetch(`${mlURL}/models`);
    res.status(response.status).send(await response.text());
});
app.post("/ai/material-predict", async (req, res) => {
    const body = z.object({
        target: z.string().default("compressive_strength_mpa"),
        model: z.string().default("best"),
        inputFeatures: z.record(z.union([z.number(), z.string()])),
    }).parse(req.body);
    const response = await fetch(`${mlURL}/predict`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
    res.status(response.status).send(await response.text());
});
app.post(["/ai/materials/predict", "/api/materials/predict"], async (req, res) => {
    const body = z.object({
        projectId: z.string().min(1),
        materialId: z.string().optional(),
        materialType: z.enum(["concrete", "soil"]).default("concrete"),
        inputFeatures: z.record(z.number()),
    }).parse(req.body);
    const targets = body.materialType === "soil"
        ? ["cbr"]
        : ["compressive_strength_mpa", "tensile_strength_mpa", "permeability"];
    const result = await proxyJSON(`${mlURL}/predict/materials`, {
        targets,
        inputFeatures: body.inputFeatures,
    });
    const binder = (body.inputFeatures.cement_kg ?? 0)
        + (body.inputFeatures.fly_ash_kg ?? 0)
        + (body.inputFeatures.ggbss_kg ?? 0)
        + (body.inputFeatures.silica_fume_kg ?? 0);
    const waterBinderRatio = binder > 0 ? (body.inputFeatures.water_kg ?? 0) / binder : undefined;
    const explanations = body.materialType === "concrete"
        ? [
            waterBinderRatio === undefined
                ? "Add binder and water quantities to calculate the water-to-binder effect."
                : `Water-to-binder ratio is ${waterBinderRatio.toFixed(3)}; lower ratios generally improve predicted strength.`,
            `Prediction reflects the submitted ${body.inputFeatures.age_days ?? 28}-day curing age.`,
        ]
        : ["Prediction reflects moisture, density, grading, and liquid-limit inputs."];
    const unavailable = Array.isArray(result.unavailableTargets) ? result.unavailableTargets.map(String) : [];
    if (unavailable.length) {
        explanations.push(`Unavailable properties require trained models: ${unavailable.join(", ")}.`);
    }
    const models = result.models && typeof result.models === "object"
        ? Object.values(result.models).map(String)
        : [];
    res.json({
        projectId: body.projectId,
        materialId: body.materialId,
        prediction: result.predictions,
        model: [...new Set(models)].join(", "),
        confidence: Number(result.confidence),
        explanations,
    });
});
app.post(["/ai/materials/optimize", "/api/materials/optimize"], async (req, res) => {
    let result;
    try {
        result = await proxyJSON(`${mlURL}/optimize`, req.body);
    }
    catch {
        result = await optimizeMix(req.body);
    }
    res.json(result);
});
app.post("/ai/defect-qc", async (req, res) => {
    const body = z.object({
        imageBase64: z.string().min(1),
        bimElementId: z.string().optional(),
    }).parse(req.body);
    const response = await fetch(`${mlURL}/qc/image`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
    res.status(response.status).send(await response.text());
});
app.post("/ai/qc-report", async (req, res) => {
    const body = z.object({ projectId: z.string(), testIds: z.array(z.string()) }).parse(req.body);
    const { rows } = await pool.query("select * from material_tests where project_id=$1 and id = any($2::uuid[])", [body.projectId, body.testIds]);
    res.json({ markdown: await llm.generateQCReport(rows) });
});
app.post("/api/reports/material-test", async (req, res) => {
    const body = z.object({ projectId: z.string().uuid(), testIds: uuidList }).parse(req.body);
    const { rows } = await pool.query(`select material_tests.*, materials.name as material_name, bim_elements.external_guid
     from material_tests
     left join materials on materials.id=material_tests.material_id
     left join bim_elements on bim_elements.id=material_tests.bim_element_id
     where material_tests.project_id=$1
     and (cardinality($2::uuid[])=0 or material_tests.id=any($2::uuid[]))`, [body.projectId, body.testIds]);
    const markdown = await llm.generateQCReport(rows);
    await pool.query(`insert into ai_reports(project_id,report_type,title,content_md,source_payload)
     values($1,'material_test',$2,$3,$4)`, [body.projectId, "Material Test Report", markdown, { testIds: body.testIds }]);
    res.json({ markdown });
});
app.post("/api/tests/report", async (req, res) => {
    const body = z.object({ projectId: z.string().uuid(), testIds: uuidList }).parse(req.body);
    const { rows } = await pool.query(`select material_tests.*, materials.name as material_name, bim_elements.external_guid
     from material_tests
     left join materials on materials.id=material_tests.material_id
     left join bim_elements on bim_elements.id=material_tests.bim_element_id
     where material_tests.project_id=$1
     and (cardinality($2::uuid[])=0 or material_tests.id=any($2::uuid[]))`, [body.projectId, body.testIds]);
    const markdown = await llm.generateQCReport(rows);
    await pool.query(`insert into ai_reports(project_id,report_type,title,content_md,source_payload)
     values($1,'material_test',$2,$3,$4)`, [body.projectId, "Material Test Report", markdown, { testIds: body.testIds }]);
    res.json({ markdown });
});
app.post("/ai/design-copilot", async (req, res) => {
    res.json(await llm.structured("Suggest 3 BIM-linked envelope and structure strategies with energy, carbon, daylight, and acoustic estimates. Return JSON.", req.body));
});
app.post("/ai/fabrication-planner", async (req, res) => {
    res.json(await llm.structured("Partition BIM assemblies into manufacturable modules and return modules, process_plan, QA checkpoints, waste, time, and risks as JSON.", req.body));
});
app.post("/api/uploads/file", upload.single("file"), async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        bucket: z.string().default("project-files"),
    }).parse(req.body);
    await requireProjectUploadAccess(body.projectId, res.locals.userId);
    if (!req.file)
        return res.status(400).json({ error: "No file was provided." });
    if (!allowedUploadBuckets.has(body.bucket)) {
        return res.status(400).json({ error: "Upload bucket is not allowed." });
    }
    if (!allowedMimeTypes.has(req.file.mimetype)) {
        return res.status(415).json({ error: "File MIME type is not allowed." });
    }
    const safeName = req.file.originalname
        .normalize("NFKD")
        .replace(/[^A-Za-z0-9._-]/g, "-")
        .slice(-120) || "upload.bin";
    const path = `${body.projectId}/${Date.now()}-${randomUUID()}-${safeName}`;
    const { error } = await storageClient().storage
        .from(body.bucket)
        .upload(path, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: false,
    });
    if (error)
        throw error;
    res.status(201).json({
        path,
        bucket: body.bucket,
        contentType: req.file.mimetype,
        size: req.file.size,
    });
});
app.post("/api/uploads/signed-url", async (req, res) => {
    const body = z.object({
        projectId: z.string().uuid(),
        bucket: z.string(),
        path: z.string().min(1),
        expiresIn: z.number().int().min(60).max(86400).default(3600),
    }).parse(req.body);
    await requireProjectUploadAccess(body.projectId, res.locals.userId);
    if (!allowedUploadBuckets.has(body.bucket)) {
        return res.status(400).json({ error: "Upload bucket is not allowed." });
    }
    if (!body.path.startsWith(`${body.projectId}/`)) {
        return res.status(400).json({ error: "Storage path must belong to the supplied project." });
    }
    const { data, error } = await storageClient().storage
        .from(body.bucket)
        .createSignedUrl(body.path, body.expiresIn);
    if (error)
        throw error;
    res.json({ signedURL: data.signedUrl, expiresIn: body.expiresIn });
});
app.use((error, _req, res, _next) => {
    const message = error instanceof Error ? error.message : "Unknown server error";
    const status = error instanceof UploadAccessError
        ? 403
        : error instanceof z.ZodError || error instanceof multer.MulterError
            ? 400
            : 500;
    const upstreamStatus = error instanceof Error && "status" in error ? Number(error.status) : undefined;
    res.status(upstreamStatus ?? status).json({ error: message });
});
startRetrainingScheduler();
export function startServer() {
    return app.listen(Number(process.env.PORT ?? 3000), () => {
        console.log(`WCS-BIM API listening on port ${process.env.PORT ?? 3000}`);
    });
}
if (process.env.NODE_ENV !== "test")
    startServer();
