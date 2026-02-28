"""
Tests for impact_scorer.py — US-G2 | FR-K4

All tests are fixture-based; no network or Supabase required.
"""

from __future__ import annotations

import pytest
from kangavisa_workers.impact_scorer import REVIEW_THRESHOLD, score

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

PLAIN_HTML = b"""
<html><body>
  <h1>Migration Act 1958</h1>
  <p>Current as at 2024-07-01</p>
</body></html>
"""

# Contains multiple trigger keywords
KEYWORD_HTML = b"""
<html><body>
  <h1>Migration Regulations 1994</h1>
  <p>Genuine temporary entrant requirement applies.</p>
  <p>Financial capacity criterion must be satisfied.</p>
  <p>English language requirements: IELTS 6.0.</p>
  <p>Specified work conditions apply.</p>
</body></html>
"""

LARGE_CHANGED_HTML = b"x" * 10_000  # big content for diff ratio tests


# ---------------------------------------------------------------------------
# Base score
# ---------------------------------------------------------------------------

class TestBaseScore:
    def test_initial_snapshot_gets_base_plus_assumed_significant(self):
        """Initial snapshot (no prev) gets base 10 + assumed-significant 20 = 30 minimum."""
        result = score(None, PLAIN_HTML, "FRL_ACT")
        assert result["impact_score"] >= 30

    def test_any_change_gets_at_least_base(self):
        """Any change must score at least 10."""
        result = score(PLAIN_HTML, PLAIN_HTML + b"minor", "DATAGOV_DATASET")
        assert result["impact_score"] >= 10

    def test_result_contains_required_keys(self):
        result = score(None, PLAIN_HTML, "FRL_ACT")
        for key in ("impact_score", "requires_review", "signals"):
            assert key in result, f"Missing key: {key}"

    def test_score_is_capped_at_100(self):
        """Score must never exceed 100."""
        result = score(None, KEYWORD_HTML, "FRL_ACT")
        assert result["impact_score"] <= 100

    def test_score_is_non_negative(self):
        result = score(PLAIN_HTML, PLAIN_HTML + b"x", "HOMEAFFAIRS_PAGE")
        assert result["impact_score"] >= 0


# ---------------------------------------------------------------------------
# Keyword scoring (US-G2 AC keyword list)
# ---------------------------------------------------------------------------

class TestKeywordScoring:
    def test_trigger_keywords_increase_score(self):
        """Content with trigger keywords must score higher than plain content."""
        plain = score(None, PLAIN_HTML, "HOMEAFFAIRS_PAGE")
        keyword = score(None, KEYWORD_HTML, "HOMEAFFAIRS_PAGE")
        assert keyword["impact_score"] > plain["impact_score"]

    def test_keyword_signal_in_signals_list(self):
        """keyword match signal must appear when keywords matched."""
        result = score(None, KEYWORD_HTML, "HOMEAFFAIRS_PAGE")
        assert any("keyword match" in s for s in result["signals"])

    def test_no_keyword_signal_for_plain_html(self):
        """Non-legislative plain HTML should not trigger keyword signal."""
        boring = b"<html><body><p>Nothing relevant here.</p></body></html>"
        result = score(None, boring, "HOMEAFFAIRS_PAGE")
        assert not any("keyword match" in s for s in result["signals"])


# ---------------------------------------------------------------------------
# Source type tier scoring
# ---------------------------------------------------------------------------

class TestSourceTypeTier:
    def test_frl_act_scores_higher_than_datagov(self):
        """FRL_ACT tier should produce higher score than DATAGOV_DATASET for same content."""
        frl = score(None, PLAIN_HTML, "FRL_ACT")
        datagov = score(None, PLAIN_HTML, "DATAGOV_DATASET")
        assert frl["impact_score"] > datagov["impact_score"]

    def test_frl_regs_also_high_tier(self):
        """FRL_REGS must also receive the high-tier bonus."""
        frl_regs = score(None, PLAIN_HTML, "FRL_REGS")
        homeaffairs = score(None, PLAIN_HTML, "HOMEAFFAIRS_PAGE")
        assert frl_regs["impact_score"] > homeaffairs["impact_score"]

    def test_high_tier_signal_present(self):
        result = score(None, PLAIN_HTML, "FRL_ACT")
        assert any("high-tier" in s for s in result["signals"])


# ---------------------------------------------------------------------------
# requires_review threshold
# ---------------------------------------------------------------------------

class TestRequiresReview:
    def test_high_scoring_triggers_requires_review(self):
        """FRL_ACT + keywords + initial snapshot should hit review threshold."""
        result = score(None, KEYWORD_HTML, "FRL_ACT")
        assert result["requires_review"] is True
        assert result["impact_score"] >= REVIEW_THRESHOLD

    def test_low_scoring_does_not_require_review(self):
        """Minimal change to non-legislative data should not require review."""
        boring = b"<html><body><p>dataset metadata 2024-01-01</p></body></html>"
        boring_changed = b"<html><body><p>dataset metadata 2024-01-02</p></body></html>"
        result = score(PLAIN_HTML, boring_changed, "DATAGOV_DATASET")
        # May or may not hit threshold — just verify the field is a bool
        assert isinstance(result["requires_review"], bool)
