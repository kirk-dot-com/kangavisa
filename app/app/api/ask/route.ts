// POST /api/ask — KB-grounded streaming LLM endpoint
// US-F1 | FR-K6
// Returns text/event-stream (SSE) with token chunks, then a final metadata frame.

import { NextRequest, NextResponse } from "next/server";
import { lint } from "../../../lib/safety-lint";
import { askLLMStream } from "../../../lib/llm-service";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
    let body: { query?: string; subclass?: string; caseDate?: string };
    try {
        body = await req.json();
    } catch {
        return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
    }

    const { query, subclass, caseDate } = body;
    if (!query || !subclass) {
        return NextResponse.json({ error: "query and subclass are required" }, { status: 400 });
    }

    // 1. Run safety lint on the *user input* first (fraud/evasion check)
    const preCheck = lint(query, "", []);
    if (!preCheck.safe && preCheck.refusal) {
        // Return refusal as a single SSE event — no LLM call
        const refusalEvent = `data: ${JSON.stringify({ refusal: preCheck.refusal, done: true, safe: false })}\n\n`;
        return new Response(refusalEvent, {
            headers: {
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                Connection: "keep-alive",
            },
        });
    }

    // 2. Stream from LLM
    const caseDateObj = caseDate ? new Date(caseDate) : new Date();

    try {
        const { stream, citations, warnings } = await askLLMStream({
            userQuery: query,
            subclassCode: subclass,
            caseDate: caseDateObj,
        });

        const encoder = new TextEncoder();
        let fullAnswer = "";

        const readable = new ReadableStream({
            async start(controller) {
                try {
                    for await (const chunk of stream) {
                        const token = chunk.choices[0]?.delta?.content ?? "";
                        if (token) {
                            fullAnswer += token;
                            controller.enqueue(
                                encoder.encode(`data: ${JSON.stringify({ token })}\n\n`)
                            );
                        }
                    }

                    // 3. Post-stream safety lint on the complete answer
                    const postCheck = lint(query, fullAnswer, []);

                    controller.enqueue(
                        encoder.encode(
                            `data: ${JSON.stringify({
                                done: true,
                                safe: postCheck.safe,
                                violations: postCheck.violations,
                                citations,
                                warnings,
                            })}\n\n`
                        )
                    );
                } catch (err) {
                    controller.enqueue(
                        encoder.encode(
                            `data: ${JSON.stringify({ error: "Stream error", done: true })}\n\n`
                        )
                    );
                } finally {
                    controller.close();
                }
            },
        });

        return new Response(readable, {
            headers: {
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                Connection: "keep-alive",
                "X-Accel-Buffering": "no",
            },
        });
    } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : "LLM service error";
        return NextResponse.json({ error: msg }, { status: 500 });
    }
}
