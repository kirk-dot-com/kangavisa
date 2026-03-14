"""
conftest.py — shared pytest configuration for kangavisa_workers tests.

Forces `kangavisa_workers.db` to reload its SUPABASE_URL and
SERVICE_ROLE_KEY env var reads before each test module that needs it.
This avoids the module-cache conflict between test_db.py and
test_seed_loader.py which both set os.environ at import time.
"""

from __future__ import annotations

import importlib
import os

import pytest


@pytest.fixture(autouse=True)
def _reload_db_env(request):
    """
    If the test module sets SUPABASE_URL via os.environ but db.py has
    already been imported with different values, the module-level globals
    in db.py (SUPABASE_URL, SERVICE_ROLE_KEY) will be stale.

    This fixture reloads `kangavisa_workers.db` before each test so the
    globals always reflect the current os.environ state.
    """
    import kangavisa_workers.db as db_module
    # Re-read from environment each test
    db_module.SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
    db_module.SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
