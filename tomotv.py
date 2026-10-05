"""Run TOMO-TV:  python tomotv.py"""

import sys

if sys.version_info < (3, 9):
    sys.exit("TOMO-TV needs Python 3.9 or newer.")

try:
    import PySide6  # noqa: F401
except ImportError:
    sys.exit("PySide6 is missing. Install it with:  python -m pip install -r requirements.txt")

from tomotv.app import main

if __name__ == "__main__":
    sys.exit(main())
