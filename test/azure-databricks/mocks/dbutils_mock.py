"""Mock dbutils for local development and testing.

Provides MockDbutils with widgets, notebook, fs, and secrets namespaces
that simulate Databricks dbutils behavior for offline development.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# Singleton instance
_mock_dbutils: MockDbutils | None = None


@dataclass
class FileInfo:
    """File info returned by fs.ls()."""

    path: str
    name: str
    size: int
    modificationTime: int = 0

    def isDir(self) -> bool:
        """Check if this is a directory."""
        return self.path.endswith("/")


class MockWidgets:
    """Mock dbutils.widgets for parameter handling."""

    def __init__(self) -> None:
        self._values: dict[str, str] = {}
        self._definitions: dict[str, dict[str, Any]] = {}

    def text(self, name: str, defaultValue: str = "", label: str = "") -> None:
        """Define a text widget."""
        self._definitions[name] = {
            "type": "text",
            "default": defaultValue,
            "label": label,
        }
        if name not in self._values:
            self._values[name] = defaultValue

    def dropdown(self, name: str, defaultValue: str, choices: list[str], label: str = "") -> None:
        """Define a dropdown widget."""
        self._definitions[name] = {
            "type": "dropdown",
            "default": defaultValue,
            "choices": choices,
            "label": label,
        }
        if name not in self._values:
            self._values[name] = defaultValue

    def get(self, name: str) -> str:
        """Get widget value."""
        if name in self._values:
            return self._values[name]
        if name in self._definitions:
            return self._definitions[name]["default"]
        return ""

    def getAll(self) -> dict[str, str]:
        """Get all widget values."""
        result = {}
        for name, defn in self._definitions.items():
            result[name] = self._values.get(name, defn["default"])
        return result

    def remove(self, name: str) -> None:
        """Remove a widget."""
        self._values.pop(name, None)
        self._definitions.pop(name, None)

    def removeAll(self) -> None:
        """Remove all widgets."""
        self._values.clear()
        self._definitions.clear()

    # Test helpers
    def set_value(self, name: str, value: str) -> None:
        """Set widget value (for testing)."""
        self._values[name] = value

    def set_values(self, values: dict[str, str]) -> None:
        """Set multiple widget values (for testing)."""
        self._values.update(values)


class MockNotebook:
    """Mock dbutils.notebook for notebook execution."""

    def __init__(self, dbutils: MockDbutils) -> None:
        self._dbutils = dbutils
        self.exit_value: str | None = None
        self._run_handlers: dict[str, Any] = {}

    def run(
        self,
        path: str,
        timeout_seconds: int = 0,
        arguments: dict[str, str] | None = None,
    ) -> str:
        """Run a notebook and return its exit value.

        In local mode, looks for registered handlers or returns mock response.

        Args:
            path: Notebook path (relative or absolute).
            timeout_seconds: Execution timeout (ignored in mock).
            arguments: Parameters to pass to notebook.

        Returns:
            JSON string from notebook exit.
        """
        # Check for registered handler
        if path in self._run_handlers:
            handler = self._run_handlers[path]
            return handler(arguments or {})

        # Default mock response
        return json.dumps(
            {
                "mock": True,
                "path": path,
                "arguments": arguments or {},
                "message": "No handler registered for this notebook path",
            }
        )

    def exit(self, value: str) -> None:
        """Exit notebook with value.

        Args:
            value: String value to return (typically JSON).

        Raises:
            SystemExit: Always raises to simulate notebook exit.
        """
        self.exit_value = value
        raise SystemExit(0)

    def getContext(self) -> MockNotebookContext:
        """Get notebook context."""
        return MockNotebookContext()

    # Test helpers
    def register_handler(self, path: str, handler: Any) -> None:
        """Register handler for notebook.run() calls (for testing)."""
        self._run_handlers[path] = handler

    def clear_handlers(self) -> None:
        """Clear all registered handlers."""
        self._run_handlers.clear()


@dataclass
class MockNotebookContext:
    """Mock notebook context."""

    notebookPath: str = "/Workspace/mock/notebook"
    currentRunId: str = "mock-run-id"
    browserHostName: str = "mock.databricks.com"

    def toJson(self) -> str:
        """Return context as JSON."""
        return json.dumps(
            {
                "notebookPath": self.notebookPath,
                "currentRunId": self.currentRunId,
                "browserHostName": self.browserHostName,
            }
        )


class MockFS:
    """Mock dbutils.fs for file system operations."""

    def __init__(self, base_path: str | None = None) -> None:
        self._base_path = base_path

    @property
    def base_path(self) -> str:
        """Get base path, using temp directory if not set."""
        if self._base_path is not None:
            return self._base_path
        # Default to system temp directory for mock filesystem
        import tempfile

        return tempfile.gettempdir()

    def _resolve_path(self, path: str) -> Path:
        """Resolve dbfs path to local path."""
        if path.startswith("dbfs:"):
            path = path[5:]  # Remove dbfs: prefix
        elif path.startswith("/dbfs"):
            path = path[5:]  # Remove /dbfs prefix
        return Path(self.base_path) / path.lstrip("/")

    def ls(self, path: str) -> list[FileInfo]:
        """List directory contents."""
        local_path = self._resolve_path(path)
        if not local_path.exists():
            raise FileNotFoundError(f"Path does not exist: {path}")
        if not local_path.is_dir():
            raise NotADirectoryError(f"Not a directory: {path}")

        results = []
        for item in local_path.iterdir():
            stat = item.stat()
            dbfs_path = f"dbfs:{path.rstrip('/')}/{item.name}"
            if item.is_dir():
                dbfs_path += "/"
            results.append(
                FileInfo(
                    path=dbfs_path,
                    name=item.name,
                    size=stat.st_size if item.is_file() else 0,
                    modificationTime=int(stat.st_mtime * 1000),
                )
            )
        return results

    def mkdirs(self, path: str) -> bool:
        """Create directory and parents."""
        local_path = self._resolve_path(path)
        local_path.mkdir(parents=True, exist_ok=True)
        return True

    def rm(self, path: str, recurse: bool = False) -> bool:
        """Remove file or directory."""
        local_path = self._resolve_path(path)
        if not local_path.exists():
            return True  # Databricks doesn't error on missing files
        if local_path.is_dir():
            if recurse:
                import shutil

                shutil.rmtree(local_path)
            else:
                local_path.rmdir()
        else:
            local_path.unlink()
        return True

    def cp(self, src: str, dst: str, recurse: bool = False) -> bool:
        """Copy file or directory."""
        import shutil

        src_path = self._resolve_path(src)
        dst_path = self._resolve_path(dst)
        if src_path.is_dir():
            if recurse:
                shutil.copytree(src_path, dst_path)
            else:
                raise IsADirectoryError(f"Cannot copy directory without recurse=True: {src}")
        else:
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
        return True

    def mv(self, src: str, dst: str, recurse: bool = False) -> bool:
        """Move file or directory."""
        import shutil

        src_path = self._resolve_path(src)
        dst_path = self._resolve_path(dst)
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src_path), str(dst_path))
        return True

    def put(self, path: str, contents: str, overwrite: bool = False) -> bool:
        """Write string contents to file."""
        local_path = self._resolve_path(path)
        if local_path.exists() and not overwrite:
            raise FileExistsError(f"File exists and overwrite=False: {path}")
        local_path.parent.mkdir(parents=True, exist_ok=True)
        local_path.write_text(contents)
        return True

    def head(self, path: str, maxBytes: int = 65536) -> str:
        """Read first N bytes of file."""
        local_path = self._resolve_path(path)
        with open(local_path) as f:
            return f.read(maxBytes)


class MockSecrets:
    """Mock dbutils.secrets for secret management."""

    def __init__(self) -> None:
        self._secrets: dict[str, dict[str, str]] = {}

    def get(self, scope: str, key: str) -> str:
        """Get secret value."""
        if scope not in self._secrets:
            raise KeyError(f"Secret scope not found: {scope}")
        if key not in self._secrets[scope]:
            raise KeyError(f"Secret key not found: {scope}/{key}")
        return self._secrets[scope][key]

    def list(self, scope: str) -> list[dict[str, str]]:
        """List secrets in scope."""
        if scope not in self._secrets:
            return []
        return [{"key": k} for k in self._secrets[scope].keys()]

    def listScopes(self) -> list[dict[str, str]]:  # type: ignore[valid-type]
        """List all scopes."""
        return [{"name": s} for s in self._secrets.keys()]

    # Test helpers
    def set_secret(self, scope: str, key: str, value: str) -> None:
        """Set secret value (for testing)."""
        if scope not in self._secrets:
            self._secrets[scope] = {}
        self._secrets[scope][key] = value

    def clear_secrets(self) -> None:
        """Clear all secrets."""
        self._secrets.clear()


@dataclass
class MockDbutils:
    """Mock dbutils with all namespaces."""

    widgets: MockWidgets = field(default_factory=MockWidgets)
    fs: MockFS = field(default_factory=MockFS)
    secrets: MockSecrets = field(default_factory=MockSecrets)
    notebook: MockNotebook = field(init=False)

    def __post_init__(self) -> None:
        self.notebook = MockNotebook(self)

    def reset(self) -> None:
        """Reset all mock state."""
        self.widgets = MockWidgets()
        self.fs = MockFS()
        self.secrets = MockSecrets()
        self.notebook = MockNotebook(self)


def get_mock_dbutils() -> MockDbutils:
    """Get singleton MockDbutils instance."""
    global _mock_dbutils
    if _mock_dbutils is None:
        _mock_dbutils = MockDbutils()
    return _mock_dbutils


def reset_mock_dbutils() -> None:
    """Reset singleton MockDbutils instance."""
    global _mock_dbutils
    if _mock_dbutils is not None:
        _mock_dbutils.reset()
    else:
        _mock_dbutils = MockDbutils()
