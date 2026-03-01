/**
 * safety-lint.ts — Runtime safety middleware for KangaVisa outputs.
 *
 * US-C3 | FR-K5
 * Covers testcases.md S-01 (fraud refusal) and S-02 (evasion refusal).
 *
 * Applied before any user-facing output is rendered. Checks for:
 *   1. Forbidden phrases (determinative or guaranteeing)
 *   2. Citation enforcement (criteria statements must have a source)
 *   3. Fraud/evasion request patterns
 */

// ---------------------------------------------------------------------------
// Forbidden phrases (US-C3 | testcases.md §1 global AC)
// ---------------------------------------------------------------------------

export const FORBIDDEN_PHRASES = [
    "you are eligible",
    "you will be approved",
    "you are approved",
    "you definitely qualify",
    "guaranteed",
    "i guarantee",
    "i can guarantee",
    "you qualify",
    "you will get",
    "you will receive your visa",
    "your application will succeed",
    "i certify",
    "i confirm you are eligible",
    "definitely eligible",
    "100% eligible",
    "100% approved",
] as const;

// ---------------------------------------------------------------------------
// Evasion / fraud request patterns (S-01, S-02)
// ---------------------------------------------------------------------------

export const FRAUD_PATTERNS = [
    "fake payslip",
    "fake letter",
    "forged document",
    "forge a",
    "forge my",
    "forge the",
    "fabricate evidence",
    "fabricate a",
    "hide gaps",
    "hide the",           // catches "hide the employment gaps"
    "conceal gaps",
    "hide my history",
    "conceal my history",
    "hide from the department",
    "avoid detection",
    "bypass the character test",
    "bypass character check",
    "employment gaps",    // any query about hiding employment gaps
    "cover up",
    "falsify",
] as const;

// ---------------------------------------------------------------------------
// Safe refusal text (shown when fraud/evasion is detected)
// ---------------------------------------------------------------------------

export const FRAUD_REFUSAL_TEXT =
    "KangaVisa cannot help with requests to create false, misleading, or fabricated documents or information. " +
    "Providing false information to the Department of Home Affairs is a serious offence and grounds for visa refusal or cancellation. " +
    "If you're concerned about gaps or inconsistencies in your history, we recommend consulting a registered migration agent (RMA) " +
    "who can help you present your circumstances honestly and accurately.";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface LintResult {
    /** true if the content passed all safety checks */
    safe: boolean;
    /** Human-readable description of each violation found */
    violations: string[];
    /** Set if this is a fraud/evasion request — show to user instead of any other output */
    refusal?: string;
}

export interface CitationCheckItem {
    /** The criteria statement text */
    statement: string;
    /** Tier-0/1 citation attached to the statement (null if missing) */
    citation: string | null;
}

// ---------------------------------------------------------------------------
// Core lint functions
// ---------------------------------------------------------------------------

/**
 * Check output text for forbidden determinative phrases.
 * Returns list of violation strings (empty = clean).
 */
export function checkForbiddenPhrases(text: string): string[] {
    const lower = text.toLowerCase();
    return FORBIDDEN_PHRASES.filter((phrase) => lower.includes(phrase)).map(
        (phrase) => `Forbidden phrase detected: "${phrase}"`
    );
}

/**
 * Check input (user query) for fraud/evasion request patterns.
 * Returns list of matched patterns (empty = no fraud signals).
 */
export function checkFraudPatterns(userInput: string): string[] {
    const lower = userInput.toLowerCase();
    return FRAUD_PATTERNS.filter((pattern) => lower.includes(pattern)).map(
        (pattern) => `Fraud/evasion pattern detected in user input: "${pattern}"`
    );
}

/**
 * FR-K5: Check that all criteria-linked statements have a citation.
 * *items* is a list of {statement, citation} pairs prepared by the response composer.
 * Returns violation strings for any item with citation = null.
 */
export function checkCitations(items: CitationCheckItem[]): string[] {
    return items
        .filter((item) => item.citation === null || item.citation.trim() === "")
        .map(
            (item) =>
                `Missing citation for criteria statement: "${item.statement.substring(0, 80)}..."`
        );
}

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

/**
 * US-C3 | FR-K5: Run full safety lint pipeline.
 *
 * *userInput* — original user query (checked for fraud patterns)
 * *outputText* — proposed response text (checked for forbidden phrases)
 * *citationItems* — (optional) criteria claims with attached citations
 *
 * Returns LintResult. If `refusal` is set, caller MUST show refusal
 * text and suppress the original response entirely.
 */
export function lint(
    userInput: string,
    outputText: string,
    citationItems: CitationCheckItem[] = []
): LintResult {
    const violations: string[] = [];

    // 1. Check for fraud/evasion request first (highest priority)
    const fraudMatches = checkFraudPatterns(userInput);
    if (fraudMatches.length > 0) {
        return {
            safe: false,
            violations: fraudMatches,
            refusal: FRAUD_REFUSAL_TEXT,
        };
    }

    // 2. Check output for forbidden phrases
    violations.push(...checkForbiddenPhrases(outputText));

    // 3. Check citations
    violations.push(...checkCitations(citationItems));

    return {
        safe: violations.length === 0,
        violations,
    };
}
