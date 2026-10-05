"""Saves TOMO-TV's state as a JSON file, safely."""

from __future__ import annotations

import json
import os
import shutil
import tempfile


class Store:
    def __init__(self, path: str):
        self.path = path

    def load(self) -> dict:
        for candidate in (self.path, self.path + ".bak"):
            try:
                with open(candidate, "r", encoding="utf-8") as f:
                    data = json.load(f)
                if isinstance(data, dict):
                    return data
            except FileNotFoundError:
                continue
            except (OSError, ValueError):
                # Keep the broken file around for inspection, then try the backup.
                try:
                    shutil.copyfile(candidate, candidate + ".broken")
                except OSError:
                    pass
        return {}

    def save(self, data: dict) -> None:
        folder = os.path.dirname(self.path) or "."
        os.makedirs(folder, exist_ok=True)
        fd, tmp = tempfile.mkstemp(prefix=".state-", suffix=".json", dir=folder)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=1)
                f.flush()
                os.fsync(f.fileno())
            if os.path.exists(self.path):
                try:
                    shutil.copyfile(self.path, self.path + ".bak")
                except OSError:
                    pass
            os.replace(tmp, self.path)
        except BaseException:
            try:
                os.remove(tmp)
            except OSError:
                pass
            raise
