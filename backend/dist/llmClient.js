const qcPrompt = `You are an RPA-style assistant for a construction materials lab.
Detect non-conforming results, group by mix, age, and test type, and produce markdown sections: Summary, Non-conformances, Detailed Results Table, Recommendations. Reference specimen and BIM element IDs.`;
export class LLMClient {
    baseURL;
    apiKey;
    constructor(baseURL = process.env.LLM_BASE_URL, apiKey = process.env.LLM_API_KEY) {
        this.baseURL = baseURL;
        this.apiKey = apiKey;
    }
    async generateQCReport(tests) {
        if (!this.baseURL || !this.apiKey) {
            return `# QA Report\n\n## Summary\n${tests.length} test record(s) loaded.\n\n## Recommendations\nReview all non-conforming records with the responsible engineer.`;
        }
        const response = await fetch(`${this.baseURL}/chat`, {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${this.apiKey}` },
            body: JSON.stringify({ model: "codex", prompt: qcPrompt, input: { tests } }),
        });
        if (!response.ok)
            throw new Error(`LLM request failed: ${response.status}`);
        const data = await response.json();
        return data.text;
    }
    async structured(prompt, input) {
        if (!this.baseURL || !this.apiKey)
            return { prompt, input, mode: "offline-template" };
        const response = await fetch(`${this.baseURL}/chat`, {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${this.apiKey}` },
            body: JSON.stringify({ model: "codex", prompt, input }),
        });
        if (!response.ok)
            throw new Error(`LLM request failed: ${response.status}`);
        const data = await response.json();
        return JSON.parse(data.text);
    }
}
