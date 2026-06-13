import { spawn } from "node:child_process";
import path from "node:path";

const python = process.env.PYTHON_PATH ?? "python3";
const script = path.join(process.cwd(), "python", "optimizer.py");
const timeoutMs = Number(process.env.OPTIMIZER_TIMEOUT_MS ?? 15_000);

export function runOptimizer(payload: unknown): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    const process = spawn(python, [script], { stdio: ["pipe", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    let settled = false;
    const timer = setTimeout(() => {
      settled = true;
      process.kill("SIGKILL");
      reject(new Error(`Optimizer exceeded ${timeoutMs}ms timeout.`));
    }, timeoutMs);

    process.stdout.on("data", (chunk: Buffer) => { stdout += chunk.toString(); });
    process.stderr.on("data", (chunk: Buffer) => { stderr += chunk.toString(); });
    process.on("error", (error) => {
      clearTimeout(timer);
      if (!settled) reject(error);
    });
    process.on("close", (code) => {
      clearTimeout(timer);
      if (settled) return;
      if (code !== 0) {
        reject(new Error(stderr.trim() || `Optimizer exited with code ${code}.`));
        return;
      }
      try {
        resolve(JSON.parse(stdout) as Record<string, unknown>);
      } catch {
        reject(new Error(`Optimizer returned invalid JSON: ${stdout.slice(0, 300)}`));
      }
    });

    process.stdin.end(JSON.stringify(payload));
  });
}

export async function optimizeMix(payload: unknown) {
  return runOptimizer(payload);
}
