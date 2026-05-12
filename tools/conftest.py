"""Make the two stdlib-only tool packages importable as top-level modules.

`tools/cli/kya.py` and `tools/mcp-server/kya_mcp_server.py` are single-file
modules shipped via their own ``pyproject.toml``; for the test runs we just
need their directories on ``sys.path`` so ``import kya`` / ``import
kya_mcp_server`` resolve without an editable install.
"""

from __future__ import annotations

import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
for _sub in ("cli", "mcp-server"):
    _p = str(_TOOLS / _sub)
    if _p not in sys.path:
        sys.path.insert(0, _p)
