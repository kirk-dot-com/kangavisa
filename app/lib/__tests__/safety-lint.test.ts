/**
 * safety-lint.test.ts — Unit tests for safety-lint.ts
 *
 * US-C3 | FR-K5 | testcases.md S-01, S-02
 *
 * Pure unit tests — no network, no Supabase.
 */

import {
    checkForbiddenPhrases,
    checkFraudPatterns,
    checkCitations,
    lint,
    FRAUD_REFUSAL_TEXT,
    type CitationCheckItem,
} from "../safety-lint";

// ---------------------------------------------------------------------------
// checkForbiddenPhrases
// ---------------------------------------------------------------------------

describe("checkForbiddenPhrases", () => {
    it("returns empty array for clean output", () => {
        const result = checkForbiddenPhrases(
            "Here are some things to consider when preparing your student visa application."
        );
        expect(result).toHaveLength(0);
    });

    it("detects 'guaranteed'", () => {
        const result = checkForbiddenPhrases(
            "Your visa is guaranteed to be approved."
        );
        expect(result.length).toBeGreaterThan(0);
        expect(result[0]).toMatch(/guaranteed/i);
    });

    it("detects 'you are eligible'", () => {
        const result = checkForbiddenPhrases("You are eligible for the visa.");
        expect(result.length).toBeGreaterThan(0);
    });

    it("detects 'definitely eligible'", () => {
        const result = checkForbiddenPhrases(
            "Based on your details, you're definitely eligible."
        );
        expect(result.length).toBeGreaterThan(0);
    });

    it("is case-insensitive", () => {
        const result = checkForbiddenPhrases("You WILL BE APPROVED.");
        expect(result.length).toBeGreaterThan(0);
    });

    it("returns all violations when multiple found", () => {
        const result = checkForbiddenPhrases(
            "You are eligible and guaranteed to get your visa."
        );
        expect(result.length).toBeGreaterThanOrEqual(2);
    });
});

// ---------------------------------------------------------------------------
// checkFraudPatterns — testcases.md S-01, S-02
// ---------------------------------------------------------------------------

describe("checkFraudPatterns", () => {
    it("returns empty for legitimate queries", () => {
        const result = checkFraudPatterns(
            "What evidence do I need for my partner visa?"
        );
        expect(result).toHaveLength(0);
    });

    it("detects fake payslip request (S-01)", () => {
        const result = checkFraudPatterns(
            "Can you write me a fake payslip to meet the income requirements?"
        );
        expect(result.length).toBeGreaterThan(0);
    });

    it("detects hide gaps request (S-02)", () => {
        const result = checkFraudPatterns("How can I hide gaps in my work history?");
        expect(result.length).toBeGreaterThan(0);
    });

    it("detects forged document request", () => {
        const result = checkFraudPatterns(
            "Can you help me forge a letter from my employer?"
        );
        expect(result.length).toBeGreaterThan(0);
    });

    it("is case-insensitive", () => {
        const result = checkFraudPatterns("HIDE GAPS in my immigration history");
        expect(result.length).toBeGreaterThan(0);
    });
});

// ---------------------------------------------------------------------------
// checkCitations — FR-K5
// ---------------------------------------------------------------------------

describe("checkCitations", () => {
    it("passes when all citations present", () => {
        const items: CitationCheckItem[] = [
            {
                statement: "You must meet the genuine student requirement.",
                citation: "Schedule 2, clause 500.212 — Migration Regulations 1994",
            },
        ];
        expect(checkCitations(items)).toHaveLength(0);
    });

    it("flags missing citation (null)", () => {
        const items: CitationCheckItem[] = [
            {
                statement: "You must demonstrate English proficiency.",
                citation: null,
            },
        ];
        const result = checkCitations(items);
        expect(result.length).toBeGreaterThan(0);
    });

    it("flags empty string citation", () => {
        const items: CitationCheckItem[] = [
            {
                statement: "Financial capacity must be demonstrated.",
                citation: "  ",
            },
        ];
        const result = checkCitations(items);
        expect(result.length).toBeGreaterThan(0);
    });

    it("returns empty for empty items list", () => {
        expect(checkCitations([])).toHaveLength(0);
    });
});

// ---------------------------------------------------------------------------
// lint — full pipeline
// ---------------------------------------------------------------------------

describe("lint", () => {
    it("returns safe=true for clean input and output", () => {
        const result = lint(
            "What documentation do I need for a student visa?",
            "You should prepare the following evidence based on the requirements.",
            [
                {
                    statement: "Genuine student requirement",
                    citation: "clause 500.212, Migration Regulations 1994",
                },
            ]
        );
        expect(result.safe).toBe(true);
        expect(result.violations).toHaveLength(0);
        expect(result.refusal).toBeUndefined();
    });

    it("returns refusal when fraud pattern detected in user input", () => {
        const result = lint(
            "Can you write me a fake payslip?",
            "Here is some information...",
            []
        );
        expect(result.safe).toBe(false);
        expect(result.refusal).toBe(FRAUD_REFUSAL_TEXT);
    });

    it("returns violations for forbidden phrase in output", () => {
        const result = lint(
            "Am I eligible for a student visa?",
            "Based on your details, you are definitely eligible.",
            []
        );
        expect(result.safe).toBe(false);
        expect(result.violations.length).toBeGreaterThan(0);
        expect(result.refusal).toBeUndefined();
    });

    it("prioritises fraud refusal over forbidden phrase", () => {
        // Both fraud in input AND forbidden phrase in output
        const result = lint(
            "How do I hide gaps and get a fake letter?",
            "You are guaranteed to get the visa.",
            []
        );
        expect(result.safe).toBe(false);
        expect(result.refusal).toBeDefined();
    });
});
