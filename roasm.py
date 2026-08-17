#!/usr/bin/env python3
"""
roasm.py — ROSAM project manager / build driver.

Core modes
----------
    run     Build for the current host target and execute the result.
    build   Build an executable for an explicitly selected target.
    obj     Assemble an object file for an explicitly selected target.

Management modes
----------------
    check   Static/project/toolchain checks without building.
    info    Print project/target/toolchain information.

Examples
--------
    python roasm.py run examples/fin.asm
    python roasm.py build examples/fin.asm --target windows-x64
    python roasm.py obj examples/fin.asm --target linux-x64

    python roasm.py build examples/fin.asm \
        --target windows-x64 \
        --root C:/Projects/ROSAM \
        --nasm "C:/Program Files/NASM/nasm.exe" \
        --gcc C:/msys64/mingw64/bin \
        -o build/fin.exe

Design/security notes
---------------------
* subprocess is always invoked with shell=False.
* Tool paths are resolved explicitly; PATH is used only for discovery.
* User source is never executed by roasm.py itself.
* Build/run output directories are constrained to the project unless the
  user explicitly passes an absolute path.
* Stale executable/object outputs are never used silently after a failed build.
* Source/include inspection rejects missing project directories and absolute
  includes outside the project unless --allow-external-includes is supplied.
* This is a build manager, not a sandbox. Assembly can inherently access
  registers, memory, syscalls and OS APIs; it cannot be made "safe" by static
  scanning alone.
"""

from __future__ import annotations

import argparse
import os
import platform as host_platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Sequence

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
    from rich.traceback import install as rich_traceback_install

    rich_traceback_install(show_locals=False)
except ImportError:
    print("ROSAM requires Python package 'rich'.")
    print("Install: python -m pip install rich")
    raise SystemExit(2)


console = Console()

APP_VERSION = "0.3.0"
SUPPORTED_SOURCE_SUFFIXES = {".asm", ".roasm"}

# Target -> NASM object format / GCC flags / platform file candidates.
# The driver deliberately does not invent a backend if the file isn't present.
TARGETS: dict[str, dict[str, object]] = {
    "windows-x86": {
        "nasm_format": "win32",
        "gcc_flags": ["-m32", "-mconsole"],
        "link_flags": [],
        "platform_patterns": ["windows_x86.asm", "windows_x86_*.asm"],
        "exe_suffix": ".exe",
    },
    "windows-x64": {
        "nasm_format": "win64",
        "gcc_flags": ["-m64", "-mconsole"],
        "link_flags": [],
        "platform_patterns": ["windows_x64.asm", "windows_x64_*.asm"],
        "exe_suffix": ".exe",
    },
    "windows-arm64": {
        # NASM is not an ARM64 assembler. This target is recognized for
        # project management, but requires an ARM-compatible backend/toolchain.
        "nasm_format": None,
        "gcc_flags": [],
        "link_flags": [],
        "platform_patterns": ["windows_arm64.asm", "windows_arm64_*.asm"],
        "exe_suffix": ".exe",
    },
    "linux-x86": {
        "nasm_format": "elf32",
        "gcc_flags": ["-m32"],
        "link_flags": [],
        "platform_patterns": ["linux_x86.asm", "linux_x86_*.asm"],
        "exe_suffix": "",
    },
    "linux-x64": {
        "nasm_format": "elf64",
        "gcc_flags": ["-m64"],
        "link_flags": [],
        "platform_patterns": ["linux_x64.asm", "linux_x64_*.asm"],
        "exe_suffix": "",
    },
    "linux-arm64": {
        "nasm_format": None,
        "gcc_flags": [],
        "link_flags": [],
        "platform_patterns": ["linux_arm64.s", "linux_arm64.asm", "linux_arm64_*.s"],
        "exe_suffix": "",
    },
    "macos-x64": {
        "nasm_format": "macho64",
        "gcc_flags": ["-m64"],
        "link_flags": [],
        "platform_patterns": ["macos_x64.asm", "macos_x64_*.asm"],
        "exe_suffix": "",
    },
    "macos-arm64": {
        "nasm_format": None,
        "gcc_flags": [],
        "link_flags": [],
        "platform_patterns": ["macos_arm64.s", "macos_arm64.asm", "macos_arm64_*.s"],
        "exe_suffix": "",
    },
    "riscv64": {
        "nasm_format": None,
        "gcc_flags": [],
        "link_flags": [],
        "platform_patterns": ["riscv64.s", "riscv64.asm", "riscv64_*.s"],
        "exe_suffix": "",
    },
}

ALIASES = {
    "win32": "windows-x86",
    "win-x86": "windows-x86",
    "windows32": "windows-x86",
    "win64": "windows-x64",
    "win-x64": "windows-x64",
    "windows64": "windows-x64",
    "winarm64": "windows-arm64",
    "windows-arm": "windows-arm64",
    "linux32": "linux-x86",
    "linux64": "linux-x64",
    "linux-x86_64": "linux-x64",
    "linux-aarch64": "linux-arm64",
    "linux-arm": "linux-arm64",
    "darwin-x64": "macos-x64",
    "macos64": "macos-x64",
    "darwin-arm64": "macos-arm64",
    "mac-arm64": "macos-arm64",
    "arm64": "linux-arm64",
}


@dataclass(frozen=True)
class Project:
    root: Path
    core: Path
    macros: Path
    platform: Path


@dataclass(frozen=True)
class Toolchain:
    nasm: Path
    gcc: Path


@dataclass
class CommandResult:
    command: list[str]
    returncode: int
    stdout: str = ""
    stderr: str = ""


class RosamError(RuntimeError):
    pass


# ---------- output ----------

def title(text: str) -> None:
    console.print(Panel(text, border_style="cyan", title="ROSAM"))


def ok(text: str) -> None:
    console.print(f"[bold green]✓[/bold green] {text}")


def warn(text: str) -> None:
    console.print(f"[bold yellow]![/bold yellow] {text}")


def fail(text: str) -> None:
    console.print(f"[bold red]✗[/bold red] {text}")


def info(text: str) -> None:
    console.print(f"[cyan]•[/cyan] {text}")


def die(message: str, hint: str | None = None) -> int:
    fail(message)
    if hint:
        console.print(f"  [yellow]Hint:[/yellow] {hint}")
    return 1


# ---------- filesystem / project ----------

def resolve_existing_dir(value: str, label: str) -> Path:
    p = Path(value).expanduser().resolve()
    if not p.is_dir():
        raise RosamError(f"{label} directory does not exist: {p}")
    return p


def find_project_root(source: Path, explicit: str | None) -> Project:
    roots: list[Path] = []

    if explicit:
        roots.append(Path(explicit).expanduser().resolve())

    env = os.environ.get("ROSAM_ROOT")
    if env:
        roots.append(Path(env).expanduser().resolve())

    roots.extend([source.parent.resolve(), *source.parent.resolve().parents])

    seen: set[Path] = set()
    for root in roots:
        if root in seen:
            continue
        seen.add(root)

        if not root.is_dir():
            continue

        core = root / "core"
        macros = root / "macros"
        platform_dir = root / "platform"

        if core.is_dir() and macros.is_dir() and platform_dir.is_dir():
            return Project(root, core, macros, platform_dir)

    raise RosamError(
        "ROSAM project root not found. Expected core/, macros/, and platform/."
    )


def resolve_source(value: str) -> Path:
    p = Path(value).expanduser().resolve()
    if not p.is_file():
        raise RosamError(f"Input file not found: {p}")
    if p.suffix.lower() not in SUPPORTED_SOURCE_SUFFIXES:
        raise RosamError(
            f"Unsupported source extension '{p.suffix}'. "
            "Use .asm or .roasm."
        )
    return p


def safe_output_path(
    value: str | None,
    *,
    project: Project,
    default: Path,
    allow_external: bool,
) -> Path:
    if value:
        p = Path(value).expanduser()
        if not p.is_absolute():
            p = project.root / p
        p = p.resolve()
    else:
        p = default.resolve()

    project_root = project.root.resolve()
    try:
        p.relative_to(project_root)
        inside = True
    except ValueError:
        inside = False

    if not inside and not allow_external:
        raise RosamError(
            f"Output path is outside ROSAM project: {p}. "
            "Use --allow-external-output explicitly if intended."
        )

    p.parent.mkdir(parents=True, exist_ok=True)
    return p


def project_files(project: Project) -> list[Path]:
    files: list[Path] = []
    for directory in (project.core, project.macros, project.platform):
        if directory.is_dir():
            files.extend(p for p in directory.rglob("*") if p.is_file())
    return files


# ---------- target ----------

def normalize_target(value: str) -> str:
    key = value.strip().lower()
    key = ALIASES.get(key, key)
    if key not in TARGETS:
        raise RosamError(
            f"Unsupported target '{value}'. "
            f"Available: {', '.join(TARGETS)}"
        )
    return key


def host_target() -> str:
    system = host_platform.system().lower()
    machine = host_platform.machine().lower()

    if system == "windows":
        if machine in {"amd64", "x86_64", "x64"}:
            return "windows-x64"
        if machine in {"x86", "i386", "i686"}:
            return "windows-x86"
        if machine in {"arm64", "aarch64"}:
            return "windows-arm64"

    if system == "linux":
        if machine in {"amd64", "x86_64", "x64"}:
            return "linux-x64"
        if machine in {"x86", "i386", "i686"}:
            return "linux-x86"
        if machine in {"arm64", "aarch64"}:
            return "linux-arm64"

    if system == "darwin":
        if machine in {"amd64", "x86_64"}:
            return "macos-x64"
        if machine in {"arm64", "aarch64"}:
            return "macos-arm64"

    raise RosamError(
        f"Unsupported host: {system}/{machine}. "
        "Use build/obj with --target for an explicit target."
    )


def target_config(target: str) -> dict[str, object]:
    return TARGETS[normalize_target(target)]


def platform_sources(project: Project, target: str) -> list[Path]:
    config = target_config(target)
    patterns = config["platform_patterns"]
    assert isinstance(patterns, list)

    found: list[Path] = []
    for pattern in patterns:
        found.extend(sorted(project.platform.glob(pattern)))

    unique: list[Path] = []
    seen: set[Path] = set()

    for p in found:
        p = p.resolve()
        if p.is_file() and p not in seen:
            seen.add(p)
            unique.append(p)

    return unique


# ---------- tools ----------

def explicit_candidates(name: str, value: str | None) -> list[Path]:
    if not value:
        return []

    p = Path(value).expanduser()

    if p.is_file():
        return [p.resolve()]

    if p.is_dir():
        names = [name]
        if os.name == "nt":
            names.insert(0, name + ".exe")
        return [(p / n).resolve() for n in names]

    return [p]


def resolve_tool(name: str, explicit: str | None) -> Path:
    candidates = explicit_candidates(name, explicit)

    found = shutil.which(name)
    if found:
        candidates.append(Path(found).resolve())

    if os.name == "nt":
        found_exe = shutil.which(name + ".exe")
        if found_exe:
            candidates.append(Path(found_exe).resolve())

    # NASM's common Windows installation path.
    if name == "nasm" and os.name == "nt":
        pf = os.environ.get("ProgramFiles")
        if pf:
            candidates.append(Path(pf) / "NASM" / "nasm.exe")

    seen: set[str] = set()
    for candidate in candidates:
        key = str(candidate).lower()
        if key in seen:
            continue
        seen.add(key)

        if candidate.is_file():
            return candidate

    raise RosamError(
        f"{name} was not found. "
        f"Pass --{name} with an executable or its directory."
    )


def tool_version(tool: Path, nasm: bool = False) -> str:
    args = [str(tool), "-v"] if nasm else [str(tool), "--version"]
    try:
        proc = subprocess.run(
            args,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=5,
        )
        first = (proc.stdout or "").strip().splitlines()
        return first[0] if first else "unknown"
    except Exception as exc:
        return f"unavailable ({exc})"


def check_dependencies(target: str, nasm: Path, gcc: Path) -> None:
    config = target_config(target)
    fmt = config["nasm_format"]

    if fmt is not None:
        # Verify target object format locally before modifying files.
        proc = subprocess.run(
            [str(nasm), "-hf"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=5,
        )
        if proc.returncode != 0:
            raise RosamError("NASM exists but could not execute correctly.")

    proc = subprocess.run(
        [str(gcc), "--version"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=5,
    )
    if proc.returncode != 0:
        raise RosamError("GCC exists but could not execute correctly.")


# ---------- source safety / inspection ----------

ABS_INCLUDE_RE = re.compile(
    r'^\s*%include\s+["<]((?:[A-Za-z]:[\\/]|/|\\\\)[^">]+)[">]',
    re.IGNORECASE,
)
INCLUDE_RE = re.compile(r'^\s*%include\s+["<]([^">]+)[">]', re.IGNORECASE)


@dataclass
class ScanReport:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    memory_warnings: list[str] = field(default_factory=list)
    safety_warnings: list[str] = field(default_factory=list)
    files_scanned: int = 0
    lines_scanned: int = 0


RAW_MEMORY_RE = re.compile(r"\[[^\]]+\]")
RAW_SYSCALL_RE = re.compile(r"^\s*(?:syscall|int\s+0x80)\b", re.IGNORECASE)
POINTER_RE = re.compile(r"\b(?:ptr|pointer|address)\b", re.IGNORECASE)
UNBOUNDED_RE = re.compile(r"\b(?:strcpy|strcat|gets|sprintf)\b", re.IGNORECASE)
ALLOC_RE = re.compile(r"\b(?:malloc|calloc|realloc|free|VirtualAlloc|HeapAlloc|mmap|munmap)\b", re.IGNORECASE)
PROCESS_RE = re.compile(r"\b(?:CreateProcess|execve|system|ShellExecute|WinExec)\b", re.IGNORECASE)
DESTRUCTIVE_RE = re.compile(r"\b(?:DeleteFile|MoveFile|RemoveFile|unlink|TerminateProcess|ExitProcess)\b", re.IGNORECASE)
COMMENT_RE = re.compile(r"^\s*(?:;|#|//)")


def resolve_include(current: Path, include_name: str, project: Project) -> Path | None:
    raw = Path(include_name)
    candidates = []
    if raw.is_absolute():
        candidates.append(raw)
    candidates += [current.parent / raw, project.root / raw, project.core / raw,
                   project.macros / raw, project.platform / raw]
    seen: set[Path] = set()
    for candidate in candidates:
        try:
            candidate = candidate.resolve()
        except OSError:
            continue
        if candidate in seen:
            continue
        seen.add(candidate)
        if candidate.is_file():
            return candidate
    return None


def walk_include_graph(source: Path, project: Project) -> list[Path]:
    result: list[Path] = []
    seen: set[Path] = set()
    pending = [source.resolve()]
    while pending:
        current = pending.pop()
        if current in seen or not current.is_file():
            continue
        seen.add(current)
        result.append(current)
        try:
            lines = current.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for line in lines:
            m = INCLUDE_RE.match(line)
            if not m:
                continue
            inc = resolve_include(current, m.group(1), project)
            if inc is not None and inc not in seen:
                pending.append(inc)
    return result


def inspect_source_tree(project: Project, source: Path, *, allow_external_includes: bool,
                        strict: bool) -> ScanReport:
    """Analyze only the actual source/include graph; safety findings never block."""
    report = ScanReport()
    graph = walk_include_graph(source, project)
    report.files_scanned = len(graph)
    root = project.root.resolve()

    for file in graph:
        try:
            lines = file.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError as exc:
            report.errors.append(f"Cannot read {file}: {exc}")
            continue
        report.lines_scanned += len(lines)
        section = ""
        for n, line in enumerate(lines, 1):
            stripped = line.strip()
            low = stripped.lower()
            if not stripped or COMMENT_RE.match(stripped):
                continue
            if low.startswith("section"):
                section = low
            m = ABS_INCLUDE_RE.match(line)
            if m:
                inc = Path(m.group(1)).expanduser()
                try:
                    inc.resolve().relative_to(root)
                except ValueError:
                    msg = f"{file}:{n}: external absolute include: {inc}"
                    if allow_external_includes:
                        report.warnings.append(msg)
                    else:
                        report.errors.append(msg)
            if low.startswith("%include") and '"' not in line and "<" not in line:
                report.warnings.append(f"{file}:{n}: non-standard %include syntax")
            if RAW_MEMORY_RE.search(stripped):
                report.memory_warnings.append(f"{file}:{n}: direct memory access")
            if POINTER_RE.search(stripped):
                report.memory_warnings.append(f"{file}:{n}: raw pointer/address usage")
            if UNBOUNDED_RE.search(stripped):
                report.memory_warnings.append(f"{file}:{n}: potentially unbounded string operation")
            if ALLOC_RE.search(stripped):
                report.memory_warnings.append(f"{file}:{n}: manual/raw memory allocation")
            if "section .bss" in section and re.search(r"\b(?:db|dw|dd|dq)\b", low):
                report.memory_warnings.append(f"{file}:{n}: initializer inside BSS section")
            if RAW_SYSCALL_RE.search(stripped):
                report.safety_warnings.append(f"{file}:{n}: direct syscall/interrupt")
            if PROCESS_RE.search(stripped):
                report.safety_warnings.append(f"{file}:{n}: process/shell execution primitive")
            if DESTRUCTIVE_RE.search(stripped):
                report.safety_warnings.append(f"{file}:{n}: destructive/system API")

    for file in graph:
        try:
            lines = file.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for n, line in enumerate(lines, 1):
            m = INCLUDE_RE.match(line)
            if m and resolve_include(file, m.group(1), project) is None:
                report.errors.append(f"{file}:{n}: include not found: {m.group(1)}")

    if strict:
        report.errors.extend("strict-mode: " + x for x in report.warnings)
    return report


def show_scan(report: ScanReport) -> None:
    table = Table(title="ROSAM Source / Memory Safety")
    table.add_column("Metric", style="cyan")
    table.add_column("Value")
    table.add_row("Files scanned", str(report.files_scanned))
    table.add_row("Lines scanned", str(report.lines_scanned))
    table.add_row("Errors", str(len(report.errors)))
    table.add_row("Warnings", str(len(report.warnings)))
    table.add_row("Memory warnings", str(len(report.memory_warnings)))
    table.add_row("Safety warnings", str(len(report.safety_warnings)))
    console.print(table)
    for item in report.warnings[:50]:
        warn(item)
    for item in report.memory_warnings[:80]:
        warn("[memory] " + item)
    for item in report.safety_warnings[:80]:
        warn("[safety] " + item)
    for item in report.errors[:50]:
        fail(item)


# ---------- command execution ----------

def run_checked(
    args: Sequence[str],
    *,
    cwd: Path,
    capture: bool = False,
) -> CommandResult:
    cmd = [str(x) for x in args]
    console.print("[dim]$ " + subprocess.list2cmdline(cmd) + "[/dim]")

    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            shell=False,
            text=True,
            stdout=subprocess.PIPE if capture else None,
            stderr=subprocess.PIPE if capture else None,
            check=False,
        )
    except FileNotFoundError as exc:
        raise RosamError(f"Executable not found: {cmd[0]}") from exc
    except OSError as exc:
        raise RosamError(f"Could not execute '{cmd[0]}': {exc}") from exc

    result = CommandResult(
        command=cmd,
        returncode=proc.returncode,
        stdout=proc.stdout or "",
        stderr=proc.stderr or "",
    )

    if result.returncode != 0:
        if capture:
            if result.stdout:
                console.print(result.stdout, end="")
            if result.stderr:
                console.print(result.stderr, end="")
        raise RosamError(
            f"Command failed with exit code {result.returncode}: {cmd[0]}"
        )

    return result


def include_args(project: Project) -> list[str]:
    # NASM supports -I <path> for include search paths.
    paths = [project.root, project.core, project.macros, project.platform]
    out: list[str] = []
    seen: set[str] = set()

    for p in paths:
        key = str(p.resolve()).lower() if os.name == "nt" else str(p.resolve())
        if key not in seen:
            seen.add(key)
            out += ["-I", str(p.resolve()) + os.sep]

    return out


def assemble(
    toolchain: Toolchain,
    project: Project,
    target: str,
    source: Path,
    output: Path,
) -> Path:
    config = target_config(target)
    fmt = config["nasm_format"]

    if not fmt:
        raise RosamError(
            f"Target '{target}' is not supported by NASM. "
            "This target requires an architecture-specific assembler/backend."
        )

    output.parent.mkdir(parents=True, exist_ok=True)

    target_define = "ROSAM_TARGET_" + re.sub(
        r"[^A-Za-z0-9]+", "_", target.upper()
    )

    command = [
        str(toolchain.nasm),
        "-f",
        str(fmt),
        *include_args(project),
        f"-d{target_define}",
        str(source),
        "-o",
        str(output),
    ]

    run_checked(command, cwd=project.root)

    if not output.is_file():
        raise RosamError(
            f"NASM returned success but no object was produced: {output}"
        )

    return output


def source_includes_backend(project: Project, source: Path, target: str) -> bool:
    expected = {x.lower() for x in TARGETS[target]["platform_patterns"]}
    base = Path(TARGETS[target]["platform_patterns"][0]).stem.lower()
    for file in walk_include_graph(source, project):
        name = file.name.lower()
        if name in expected or name.startswith(base + "_"):
            return True
    return False


def backend_sources_needed(project: Project, source: Path, target: str) -> list[Path]:
    if source_includes_backend(project, source, target):
        return []
    found: list[Path] = []
    for pattern in TARGETS[target]["platform_patterns"]:
        found.extend(sorted(project.platform.glob(pattern)))
    unique: list[Path] = []
    seen: set[Path] = set()
    for p in found:
        p = p.resolve()
        if p.is_file() and p not in seen:
            seen.add(p)
            unique.append(p)
    if not unique:
        raise RosamError(
            f"No platform backend found for {target}; expected one of: "
            + ", ".join(TARGETS[target]["platform_patterns"])
        )
    return unique


def compile_executable(
    toolchain: Toolchain,
    project: Project,
    target: str,
    source: Path,
    output: Path,
    extra_libs: Sequence[str],
) -> tuple[Path, list[Path]]:
    config = target_config(target)
    output.parent.mkdir(parents=True, exist_ok=True)
    main_obj = output.parent / f"{source.stem}.obj"
    assemble(toolchain, project, target, source, main_obj)

    # Important: never link a backend twice. If the program's include graph
    # already contains platform/windows_x64.asm, main_obj already contains it.
    backend_objects: list[Path] = []
    for backend in backend_sources_needed(project, source, target):
        obj = output.parent / f"{backend.stem}.obj"
        assemble(toolchain, project, target, backend, obj)
        backend_objects.append(obj)

    command = [str(toolchain.gcc), *map(str, config["gcc_flags"]),
               *map(str, config["link_flags"]), str(main_obj),
               *map(str, backend_objects)]
    for lib in extra_libs:
        clean = lib.strip()
        if clean:
            command.append(clean if clean.startswith("-l") else "-l" + clean)
    command += ["-o", str(output)]

    if output.exists():
        output.unlink()
    run_checked(command, cwd=project.root)
    if not output.is_file():
        raise RosamError(f"GCC reported success but did not create {output}")
    return main_obj, backend_objects
def remove_intermediates(paths: Iterable[Path]) -> None:
    for p in paths:
        try:
            p.unlink(missing_ok=True)
        except OSError:
            pass


# ---------- CLI ----------

def parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("source", help="Input .asm or .roasm file.")
    common.add_argument(
        "--root",
        help="ROSAM project root containing core/, macros/, platform/.",
    )
    common.add_argument(
        "--nasm",
        help="NASM executable or directory containing nasm/nasm.exe.",
    )
    common.add_argument(
        "--gcc",
        help="GCC executable or directory containing gcc/gcc.exe.",
    )
    common.add_argument(
        "--build-dir",
        default="build",
        help="Intermediate/output directory.",
    )
    common.add_argument(
        "-o",
        "--output",
        help="Output object/executable path.",
    )
    common.add_argument(
        "--allow-external-output",
        action="store_true",
        help="Allow output outside the ROSAM project root.",
    )
    common.add_argument(
        "--allow-external-includes",
        action="store_true",
        help="Allow absolute includes outside the ROSAM project root.",
    )
    common.add_argument(
        "--strict",
        action="store_true",
        help="Treat source-safety warnings as errors.",
    )
    common.add_argument(
        "--no-scan",
        action="store_true",
        help="Skip static source inspection.",
    )
    common.add_argument(
        "--lib",
        action="append",
        default=[],
        help="Additional linker library, repeatable; e.g. --lib m.",
    )

    p = argparse.ArgumentParser(
        prog="roasm",
        description="ROSAM project manager and build driver.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  roasm run examples/fin.asm
  roasm build examples/fin.asm --target windows-x64
  roasm obj examples/fin.asm --target linux-x64
  roasm check examples/fin.asm
  roasm info examples/fin.asm

  roasm build examples/fin.asm --target windows-x64 ^
      --nasm "C:\\Program Files\\NASM\\nasm.exe" ^
      --gcc C:\\msys64\\mingw64\\bin ^
      -o build\\fin.exe
""",
    )

    p.add_argument("--version", action="version", version=f"roasm {APP_VERSION}")

    sub = p.add_subparsers(dest="mode", required=True)

    p_run = sub.add_parser(
        "run",
        parents=[common],
        help="Build for the current host target and execute.",
    )
    # Run intentionally has NO --target; host target is automatic.
    p_run.add_argument(
        "--keep-temp",
        action="store_true",
        help="Keep generated object files after execution.",
    )

    p_build = sub.add_parser(
        "build",
        parents=[common],
        help="Build an executable for an explicit target.",
    )
    p_build.add_argument(
        "--target",
        required=True,
        choices=sorted(set(TARGETS) | set(ALIASES)),
        help="Explicit build target.",
    )

    p_obj = sub.add_parser(
        "obj",
        parents=[common],
        help="Produce an object file for an explicit target.",
    )
    p_obj.add_argument(
        "--target",
        required=True,
        choices=sorted(set(TARGETS) | set(ALIASES)),
        help="Explicit object target.",
    )

    p_check = sub.add_parser(
        "check",
        parents=[common],
        help="Inspect the project/source and verify the toolchain.",
    )
    p_check.add_argument(
        "--target",
        choices=sorted(set(TARGETS) | set(ALIASES)),
        help="Optional target to validate. Defaults to host target.",
    )

    p_info = sub.add_parser(
        "info",
        parents=[common],
        help="Show project, host, target and tool information.",
    )
    p_info.add_argument(
        "--target",
        choices=sorted(set(TARGETS) | set(ALIASES)),
        help="Optional target. Defaults to host target.",
    )

    return p


def show_info(
    project: Project,
    source: Path,
    target: str,
    nasm: Path,
    gcc: Path,
) -> None:
    table = Table(title="ROSAM Project", show_header=True)
    table.add_column("Property", style="cyan")
    table.add_column("Value")

    table.add_row("ROSAM", APP_VERSION)
    table.add_row("Project root", str(project.root))
    table.add_row("Source", str(source))
    table.add_row("Host OS", host_platform.system())
    table.add_row("Host CPU", host_platform.machine())
    table.add_row("Target", target)
    table.add_row("NASM", f"{nasm} — {tool_version(nasm, nasm=True)}")
    table.add_row("GCC", f"{gcc} — {tool_version(gcc)}")
    table.add_row("Core", str(project.core))
    table.add_row("Macros", str(project.macros))
    table.add_row("Platform", str(project.platform))

    console.print(table)

    if source_includes_backend(project, source, target):
        console.print("\n[bold]Platform backend:[/bold] [green]included by source[/green]")
    else:
        console.print("\n[bold]Platform backend:[/bold]")
        for backend in backend_sources_needed(project, source, target):
            console.print(f"  [green]✓[/green] {backend}")


def command_run(args: argparse.Namespace) -> int:
    source = resolve_source(args.source)
    project = find_project_root(source, args.root)
    target = host_target()

    nasm = resolve_tool("nasm", args.nasm)
    gcc = resolve_tool("gcc", args.gcc)

    # Dependency check comes before compilation.
    check_dependencies(target, nasm, gcc)

    report = inspect_source_tree(
        project,
        source,
        allow_external_includes=args.allow_external_includes,
        strict=args.strict,
    )

    if not args.no_scan:
        show_scan(report)
        if report.errors:
            return die(
                "Static inspection failed; execution was not started.",
                "Fix the errors or explicitly adjust the safety policy.",
            )

    build_dir = Path(args.build_dir)
    if not build_dir.is_absolute():
        build_dir = project.root / build_dir
    build_dir = build_dir.resolve()

    default_exe = build_dir / (
        source.stem + str(target_config(target)["exe_suffix"])
    )
    output = safe_output_path(
        args.output,
        project=project,
        default=default_exe,
        allow_external=args.allow_external_output,
    )

    title(f"RUN  •  target={target}")
    show_info(project, source, target, nasm, gcc)

    # Run mode is host-only by design.
    main_obj, backend_objects = compile_executable(
        Toolchain(nasm, gcc),
        project,
        target,
        source,
        output,
        args.lib,
    )

    try:
        console.print(
            Panel(
                f"[bold green]Executing[/bold green]\n{output}",
                border_style="green",
            )
        )
        # No shell: source cannot silently turn into a command string here.
        proc = subprocess.run(
            [str(output)],
            cwd=str(project.root),
            shell=False,
            check=False,
        )
        console.print(
            f"\n[bold]{'Success' if proc.returncode == 0 else 'Exit code'}:[/bold] "
            f"{proc.returncode}"
        )
        return proc.returncode
    finally:
        if not args.keep_temp:
            remove_intermediates([main_obj, *backend_objects])


def command_build(args: argparse.Namespace, mode: str) -> int:
    source = resolve_source(args.source)
    project = find_project_root(source, args.root)
    target = normalize_target(args.target)

    nasm = resolve_tool("nasm", args.nasm)
    gcc = resolve_tool("gcc", args.gcc)
    check_dependencies(target, nasm, gcc)

    report = inspect_source_tree(
        project,
        source,
        allow_external_includes=args.allow_external_includes,
        strict=args.strict,
    )

    if not args.no_scan:
        show_scan(report)
        if report.errors:
            return die(
                "Static inspection failed; build was not started."
            )

    build_dir = Path(args.build_dir)
    if not build_dir.is_absolute():
        build_dir = project.root / build_dir
    build_dir = build_dir.resolve()

    if mode == "obj":
        default = build_dir / f"{source.stem}.obj"
        output = safe_output_path(
            args.output,
            project=project,
            default=default,
            allow_external=args.allow_external_output,
        )

        # obj mode explicitly outputs only the program object.
        title(f"OBJ  •  target={target}")
        assemble(Toolchain(nasm, gcc), project, target, source, output)

        console.print(
            Panel(
                f"[bold green]Object created[/bold green]\n{output}",
                border_style="green",
            )
        )
        return 0

    default = build_dir / (
        source.stem + str(target_config(target)["exe_suffix"])
    )
    output = safe_output_path(
        args.output,
        project=project,
        default=default,
        allow_external=args.allow_external_output,
    )

    title(f"BUILD  •  target={target}")
    main_obj, backend_objects = compile_executable(
        Toolchain(nasm, gcc),
        project,
        target,
        source,
        output,
        args.lib,
    )

    console.print(
        Panel(
            f"[bold green]Build successful[/bold green]\n{output}",
            border_style="green",
        )
    )
    console.print(
        f"[dim]Intermediate object:[/dim] {main_obj}\n"
        f"[dim]Platform objects:[/dim] {len(backend_objects)}"
    )
    return 0


def command_check(args: argparse.Namespace) -> int:
    source = resolve_source(args.source)
    project = find_project_root(source, args.root)
    target = normalize_target(args.target) if args.target else host_target()

    nasm = resolve_tool("nasm", args.nasm)
    gcc = resolve_tool("gcc", args.gcc)
    check_dependencies(target, nasm, gcc)

    title(f"CHECK  •  target={target}")

    report = inspect_source_tree(
        project,
        source,
        allow_external_includes=args.allow_external_includes,
        strict=args.strict,
    )
    show_scan(report)

    try:
        backend_sources_needed(project, source, target)
    except RosamError:
        if not source_includes_backend(project, source, target):
            report.errors.append(f"Missing platform backend for target '{target}'.")

    if report.errors:
        fail("ROSAM check failed.")
        return 1

    ok("ROSAM check passed.")
    return 0


def command_info(args: argparse.Namespace) -> int:
    source = resolve_source(args.source)
    project = find_project_root(source, args.root)
    target = normalize_target(args.target) if args.target else host_target()

    nasm = resolve_tool("nasm", args.nasm)
    gcc = resolve_tool("gcc", args.gcc)
    check_dependencies(target, nasm, gcc)

    title("ROSAM INFO")
    show_info(project, source, target, nasm, gcc)
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)

    try:
        if args.mode == "run":
            return command_run(args)
        if args.mode == "build":
            return command_build(args, "build")
        if args.mode == "obj":
            return command_build(args, "obj")
        if args.mode == "check":
            return command_check(args)
        if args.mode == "info":
            return command_info(args)

        return die(f"Unknown mode: {args.mode}")
    except RosamError as exc:
        return die(str(exc))
    except KeyboardInterrupt:
        warn("Interrupted.")
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
