const mlURL = process.env.ML_SERVICE_URL ?? "http://127.0.0.1:8000";
const scheduleIntervalMs = Number(process.env.RETRAIN_INTERVAL_MS ?? 0);
let schedulerStarted = false;
async function mlRequest(path, method = "GET", body) {
    const response = await fetch(`${mlURL}${path}`, {
        method,
        headers: { "Content-Type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await response.text();
    let payload;
    try {
        payload = text ? JSON.parse(text) : {};
    }
    catch {
        payload = { message: text };
    }
    if (!response.ok) {
        const error = new Error(`Retraining service error ${response.status}: ${text}`);
        error.status = response.status;
        throw error;
    }
    return payload;
}
export const runRetraining = () => mlRequest("/retrain/run", "POST", {});
export const retrainingStatus = () => mlRequest("/retrain/status");
export const checkDrift = (payload) => mlRequest("/drift/check", "POST", payload);
export function startRetrainingScheduler() {
    if (schedulerStarted || !Number.isFinite(scheduleIntervalMs) || scheduleIntervalMs <= 0)
        return;
    schedulerStarted = true;
    const timer = setInterval(async () => {
        try {
            const status = await retrainingStatus();
            if (status.state !== "running")
                await runRetraining();
        }
        catch (error) {
            console.error("Scheduled retraining failed", error);
        }
    }, scheduleIntervalMs);
    timer.unref();
}
