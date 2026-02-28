"""
impact_scorer.py — Deterministic impact scoring for KB change events.

US-G2 | FR-K4: change_event scored 0-100; score >= 70 triggers requires_review.

Scoring heuristic:
  +10  base (any detected change)
  +40  content diff > 5% of document size
  +30  keyword match on trigger terms (per US-G2 AC)
  +20  source type is FRL_ACT or FRL_REGS (highest legal tier)

Maximum possible score: 100.
"""

from __future__ import annotations

# ---------------------------------------------------------------------------
# Keywords that signal high-impact legislative/policy changes (US-G2 AC)
# ---------------------------------------------------------------------------
TRIGGER_KEYWORDS = frozenset([
    "visa", "requirement", "criterion", "criteria",
    "repeal", "repealed", "schedule", "regulation",
    "english", "financial", "occupation", "specified work", "exemption",
])

HIGH_TIER_SOURCE_TYPES = frozenset(["FRL_ACT", "FRL_REGS"])

REVIEW_THRESHOLD = 70


def score(
    prev_content: bytes | None,
    curr_content: bytes,
    source_type: str,
) -> dict:
    """
    Score a detected change and return a dict:

        {
            "impact_score": int,       # 0-100
            "requires_review": bool,   # True if score >= REVIEW_THRESHOLD
            "signals": list[str],      # human-readable explanation of what fired
        }

    *prev_content* is None for an initial snapshot (no diff possible).
    """
    signals: list[str] = []
    total = 0

    # Base: any change at all
    total += 10
    signals.append("base: change detected (+10)")

    # Diff size: > 5% of document
    if prev_content is not None:
        prev_size = max(len(prev_content), 1)
        overlap = min(len(prev_content), len(curr_content))
        differing = sum(a != b for a, b in zip(prev_content[:overlap], curr_content[:overlap]))
        diff_ratio = differing / prev_size
        if diff_ratio > 0.05:
            total += 40
            signals.append(f"large diff: {diff_ratio:.1%} of document changed (+40)")
    else:
        # Initial snapshot — no prev to diff against; treat as significant
        total += 20
        signals.append("initial snapshot: no prev hash, assumed significant (+20)")

    # Keyword match in current content
    text = curr_content.decode("utf-8", errors="ignore").lower()
    matched = {kw for kw in TRIGGER_KEYWORDS if kw in text}
    if matched:
        total += 30
        signals.append(f"keyword match: {sorted(matched)} (+30)")

    # High-tier source type
    if source_type in HIGH_TIER_SOURCE_TYPES:
        total += 20
        signals.append(f"high-tier source type: {source_type} (+20)")

    total = min(total, 100)
    return {
        "impact_score": total,
        "requires_review": total >= REVIEW_THRESHOLD,
        "signals": signals,
    }
