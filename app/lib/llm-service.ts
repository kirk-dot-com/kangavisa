/**
 * llm-service.ts — KB-grounded LLM integration for KangaVisa
 *
 * US-F1 | FR-K6
 * Server-only. Never import in Client Components.
 *
 * Steps:
 * 1. Pull structured KB package (getKBPackage)
 * 2. Build system prompt grounding the LLM in requirements + evidence + flags
 * 3. Call OpenAI chat completions (streaming)
 * 4. Apply safety-lint to the final answer
 * 5. Return { stream, citations }
 */

import OpenAI from "openai";
import { getKBPackage, type KBPackage } from "./kb-service";
import { lint } from "./safety-lint";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface LLMRequest {
    userQuery: string;
    subclassCode: string;
    caseDate?: Date;
}

export interface LLMResult {
    answer: string;
    citations: string[];
    safe: boolean;
    refusal?: string;
    warnings: string[];
}

// ---------------------------------------------------------------------------
// System prompt builder (architecture.md §4.2 structured-first)
// ---------------------------------------------------------------------------

function buildSystemPrompt(pkg: KBPackage, subclassCode: string): string {
    const reqSummary = pkg.requirements
        .map(
            (r) =>
                `• [${r.requirement_type.toUpperCase()}] ${r.title}: ${r.plain_english}` +
                (r.legal_basis.length > 0
                    ? ` [Citation: ${r.legal_basis[0].citation ?? r.legal_basis[0].authority}]`
                    : "")
        )
        .join("\n");

    const flagSummary = pkg.flagTemplates
        .map(
            (f) =>
                `• [FLAG/${f.severity.toUpperCase()}] ${f.title}: ${f.why_it_matters}`
        )
        .join("\n");

    return `You are KangaVisa, an Australian immigration readiness assistant.

ROLE: Help users prepare structured, evidence-based visa application packs.
You are NOT a lawyer and do NOT give legal advice. You NEVER guarantee or predict outcomes.

CURRENT CONTEXT:
- Visa subclass: ${subclassCode}
- Case date: ${pkg.caseDate}
- Knowledge base loaded: ${pkg.requirements.length} requirements, ${pkg.flagTemplates.length} flags

REQUIREMENTS FOR THIS VISA (from Australian migration law):
${reqSummary || "No structured requirements loaded for this visa."}

RISK FLAGS FOR THIS VISA:
${flagSummary || "No flags loaded for this visa."}

RESPONSE RULES (non-negotiable):
1. Use "risk indicator" or "flag" — never "you are eligible", "guaranteed", "approved", or "you will".
2. Always include an Assumptions block at the start of your response.
3. Always end with a Next Actions block (max 5 items, each starting with a verb).
4. Cite the source for every factual criterion you state.
5. If you cannot ground a claim in the KB above, say so explicitly.
6. Write in plain English — short sentences, bullets where possible (CALD-friendly).
7. If asked about falsifying, fabricating, or hiding information: refuse clearly.`;
}

// ---------------------------------------------------------------------------
// Collect citations from the KB package for the response
// ---------------------------------------------------------------------------

function extractCitations(pkg: KBPackage): string[] {
    const citations: string[] = [];
    for (const req of pkg.requirements) {
        for (const lb of req.legal_basis) {
            const cite = lb.citation ?? lb.series ?? lb.authority;
            if (cite && !citations.includes(cite)) citations.push(cite);
        }
        for (const ob of req.operational_basis) {
            if (!citations.includes(ob.url)) citations.push(ob.url);
        }
    }
    return citations.slice(0, 8); // cap at 8 citations
}

// ---------------------------------------------------------------------------
// Main non-streaming function (used for golden tests)
// ---------------------------------------------------------------------------

export async function askLLM(req: LLMRequest): Promise<LLMResult> {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
        return {
            answer: "",
            citations: [],
            safe: false,
            refusal: "LLM service not configured — OPENAI_API_KEY missing.",
            warnings: ["OPENAI_API_KEY not set"],
        };
    }

    const caseDate = req.caseDate ?? new Date();
    const pkg = await getKBPackage(req.subclassCode, caseDate);
    const systemPrompt = buildSystemPrompt(pkg, req.subclassCode);
    const citations = extractCitations(pkg);

    const client = new OpenAI({ apiKey });

    const completion = await client.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: req.userQuery },
        ],
        max_tokens: 1200,
        temperature: 0.2,
    });

    const answer = completion.choices[0]?.message?.content ?? "";

    // Run safety lint
    const lintResult = lint(req.userQuery, answer, []);

    return {
        answer,
        citations,
        safe: lintResult.safe,
        refusal: lintResult.refusal,
        warnings: pkg.warnings,
    };
}

// ---------------------------------------------------------------------------
// Streaming function (used by /api/ask route)
// ---------------------------------------------------------------------------

export async function askLLMStream(req: LLMRequest) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error("OPENAI_API_KEY not configured");

    const caseDate = req.caseDate ?? new Date();
    const pkg = await getKBPackage(req.subclassCode, caseDate);
    const systemPrompt = buildSystemPrompt(pkg, req.subclassCode);
    const citations = extractCitations(pkg);

    const client = new OpenAI({ apiKey });

    const stream = await client.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: req.userQuery },
        ],
        max_tokens: 1200,
        temperature: 0.2,
        stream: true,
    });

    return { stream, citations, warnings: pkg.warnings };
}
