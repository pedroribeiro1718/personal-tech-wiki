#!/usr/bin/env python3
"""Small, dependency-free dashboard for the local Qwen stack."""

from __future__ import annotations

import curses
import json
import re
import subprocess
import sys
import textwrap
import time
import urllib.request

QWEN_URL = "http://127.0.0.1:30000/v1/models"
CONTAINERS = {
    "sglang": "qwen38",
    "exl3": "qwen38-full",
    "ninfer": "qwen38-ninfer",
    "udq4": "qwen38-udq4",
    "a3b": "qwen36-a3b",
}
TABS = ("Overview", "Qwen log", "Harness log", "Work log", "SearXNG log", "GPU")
LOG_TABS = {1, 2, 3, 4}
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
COLORS = False


def command(args: list[str], timeout: float = 4) -> str:
    try:
        result = subprocess.run(
            args, capture_output=True, text=True, timeout=timeout, check=False, errors="replace"
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as error:
        return f"Error running {args[0]}: {error}"
    output = result.stdout
    if result.stderr:
        output += ("\n" if output else "") + result.stderr
    return output.rstrip()


def container_state(name: str) -> str:
    value = command(
        ["docker", "container", "inspect", "--format", "{{.State.Status}}", name]
    )
    state = value.splitlines()[0] if value else "absent"
    return state if state in {"created", "running", "paused", "restarting", "removing", "exited", "dead"} else "absent"


def active_qwen() -> tuple[str, str, str]:
    states = [(recipe, name, container_state(name)) for recipe, name in CONTAINERS.items()]
    for recipe, name, state in states:
        if state == "running":
            return recipe, name, state
    for recipe, name, state in states:
        if state not in ("absent", "exited"):
            return recipe, name, state
    return "none", "none", "stopped"


def unit_state(unit: str = "local-qwen-harness.service") -> str:
    state = command(["systemctl", "--user", "is-active", unit])
    return state if state in {"active", "reloading", "inactive", "failed", "activating", "deactivating"} else "unavailable"


def api_model() -> tuple[str, str]:
    try:
        with urllib.request.urlopen(QWEN_URL, timeout=0.7) as response:
            model = json.load(response)["data"][0]
        context = model.get("max_model_len") or model.get("max_model_length") or "unknown"
        return str(model.get("id", "unknown")), f"{int(context):,}" if str(context).isdigit() else str(context)
    except Exception:
        return "unavailable", "unknown"


def grid_row(*cells: object) -> str:
    offsets = (2, 20, 36, 60)
    line = ""
    for index, (offset, cell) in enumerate(zip(offsets, cells)):
        value = str(cell)
        if index + 1 < len(cells):
            value = value[: offsets[index + 1] - offset - 1]
        line = line.ljust(offset) + value
    return line.rstrip()


def gpu_metrics() -> list[tuple[str, str]]:
    query = "memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw,power.limit"
    raw = command(["nvidia-smi", f"--query-gpu={query}", "--format=csv,noheader,nounits"])
    try:
        used, total, util, temp, power, limit = [part.strip() for part in raw.split(",")]
        return [
            ("VRAM", f"{int(float(used)):,} / {int(float(total)):,} MiB"),
            ("GPU utilization", f"{util}%"),
            ("Temperature", f"{temp} C"),
            ("Power", f"{float(power):.0f} / {float(limit):.0f} W"),
        ]
    except (ValueError, TypeError):
        return [("Metrics", raw or "unavailable")]


def overview() -> list[str]:
    recipe, container, qwen_state = active_qwen()
    model, context = api_model()
    searxng = container_state("qwen-searxng")
    processes = command(
        [
            "nvidia-smi",
            "--query-compute-apps=pid,process_name,used_memory",
            "--format=csv,noheader",
        ]
    )
    process_rows = []
    for process in processes.splitlines():
        parts = [part.strip() for part in process.split(",", 2)]
        process_rows.append(grid_row(*parts) if len(parts) == 3 else grid_row("unavailable", process))
    return [
        " SERVICES",
        grid_row("Qwen", qwen_state, container, "http://127.0.0.1:30000/v1"),
        grid_row("Harness", unit_state(), "user systemd", "http://127.0.0.1:3080"),
        grid_row("Work Harness", unit_state("local-qwen-harness-work.service"), "user systemd", "http://127.0.0.1:3081"),
        grid_row("SearXNG", searxng, "qwen-searxng", "http://127.0.0.1:8888"),
        "",
        " MODEL",
        grid_row("Recipe", recipe),
        grid_row("ID", model),
        grid_row("Context", f"{context} tokens"),
        "",
        " GPU",
        *[grid_row(*metric) for metric in gpu_metrics()],
        "",
        " COMPUTE PROCESSES",
        *(process_rows or [grid_row("none")]),
    ]


def logs_for(tab: int) -> list[str]:
    if tab == 1:
        recipe, container, state = active_qwen()
        if state != "running":
            return ["No Qwen recipe is running."]
        title = f"Qwen / {recipe} / {container}"
        output = command(["docker", "logs", "--tail", "200", container])
    elif tab == 2:
        title = "Harness / local-qwen-harness.service"
        output = command(
            ["journalctl", "--user", "-u", "local-qwen-harness.service", "-n", "200", "--no-pager"]
        )
    elif tab == 3:
        title = "Work Harness / local-qwen-harness-work.service"
        output = command(
            ["journalctl", "--user", "-u", "local-qwen-harness-work.service", "-n", "200", "--no-pager"]
        )
    else:
        title = "SearXNG / qwen-searxng"
        output = command(["docker", "logs", "--tail", "200", "qwen-searxng"])
    return [title, "", *(output.splitlines() or ["No log output."])]


def view(tab: int) -> list[str]:
    if tab == 0:
        return overview()
    if tab in LOG_TABS:
        return logs_for(tab)
    return command(["nvidia-smi"]).splitlines()


def header() -> str:
    recipe, _, state = active_qwen()
    _, context = api_model()
    return f"Local AI   Recipe: {recipe}   Context: {context}   Qwen: {state}"


def clean(line: str) -> str:
    line = ANSI.sub("", line).replace("\t", "    ").replace("\r", "")
    return "".join(character for character in line if character.isprintable())


def init_colors() -> None:
    global COLORS
    if not curses.has_colors():
        return
    curses.start_color()
    background = curses.COLOR_BLACK
    try:
        curses.use_default_colors()
        background = -1
    except curses.error:
        pass
    warning = 245 if curses.COLORS >= 256 else curses.COLOR_WHITE
    error = 139 if curses.COLORS >= 256 else curses.COLOR_MAGENTA
    for pair, foreground in enumerate((curses.COLOR_CYAN, curses.COLOR_GREEN, warning, error), 1):
        curses.init_pair(pair, foreground, background)
    COLORS = True


def color(pair: int) -> int:
    return curses.color_pair(pair) if COLORS else 0


def content_style(line: str, tab: int) -> int:
    label = line.strip()
    lower = label.lower()
    if label in {"SERVICES", "MODEL", "GPU", "COMPUTE PROCESSES"}:
        return curses.A_BOLD | color(1)
    if tab == 0 and line[2:20].strip() in {"Qwen", "Harness", "Work Harness", "SearXNG"}:
        state = line[20:36].strip()
        return color(2) if state in {"running", "active"} else curses.A_DIM | color(3)
    if any(word in lower for word in ("error", "failed", "traceback", "fatal")):
        return curses.A_DIM | color(4)
    if any(word in lower for word in ("warn", "unavailable")):
        return curses.A_DIM | color(3)
    return 0


def horizontal_border(width: int) -> str:
    return "+" + "-" * max(0, width - 4) + "+"


def wrapped(lines: list[str], width: int) -> list[str]:
    result: list[str] = []
    for line in lines:
        result.extend(textwrap.wrap(clean(line), width=width, replace_whitespace=False) or [""])
    return result


def put(screen: curses.window, row: int, column: int, text: str, style: int = 0) -> None:
    try:
        screen.addnstr(row, column, text, max(0, screen.getmaxyx()[1] - column - 1), style)
    except curses.error:
        pass


def draw(screen: curses.window, title: str, tab: int, lines: list[str], top: int, follow: bool) -> int:
    screen.erase()
    height, width = screen.getmaxyx()
    if height < 12 or width < 60:
        put(screen, 0, 0, "Terminal too small; resize to at least 60x12. Press q to exit.")
        screen.refresh()
        return 0

    put(screen, 0, 1, title, curses.A_BOLD | color(1))
    position = 1
    for index, name in enumerate(TABS):
        if index:
            put(screen, 2, position, " | ", curses.A_DIM | color(1))
            position += 3
        label = f" {index + 1} {name} "
        style = curses.A_REVERSE | curses.A_BOLD if index == tab else color(1)
        put(screen, 2, position, label, style)
        position += len(label)

    content_height = height - 6
    content_width = width - 4
    display = wrapped(lines, content_width)
    if follow and tab in LOG_TABS:
        top = max(0, len(display) - content_height)
    top = min(max(0, top), max(0, len(display) - content_height))
    border = curses.A_DIM | color(1)
    put(screen, 3, 1, horizontal_border(width), border)
    for offset in range(content_height):
        put(screen, 4 + offset, 1, "|", border)
        put(screen, 4 + offset, width - 2, "|", border)
        if top + offset < len(display):
            line = display[top + offset]
            put(screen, 4 + offset, 2, line, content_style(line, tab))
    put(screen, height - 2, 1, horizontal_border(width), border)
    mode = "   [following]" if follow and tab in LOG_TABS else ""
    put(screen, height - 1, 1, f"Tab/1-6 view  Up/Down/Pg scroll  f follow  r refresh  q quit{mode}")
    screen.refresh()
    return top


def main(screen: curses.window) -> None:
    try:
        curses.curs_set(0)
    except curses.error:
        pass
    init_colors()
    screen.timeout(200)
    tab, top, follow = 0, 0, True
    lines: list[str] = []
    title = "Local AI"
    refreshed = 0.0
    while True:
        now = time.monotonic()
        if now - refreshed >= 1.0:
            title, lines, refreshed = header(), view(tab), now
        top = draw(screen, title, tab, lines, top, follow)
        key = screen.getch()
        if key in (ord("q"), 27):
            return
        if key in (9, curses.KEY_BTAB) or ord("1") <= key <= ord("6"):
            tab = (tab + (-1 if key == curses.KEY_BTAB else 1)) % len(TABS) if key in (9, curses.KEY_BTAB) else key - ord("1")
            top, follow, refreshed = 0, True, 0.0
        elif key in (curses.KEY_UP, curses.KEY_PPAGE, curses.KEY_HOME):
            follow = False
            top = 0 if key == curses.KEY_HOME else max(0, top - (10 if key == curses.KEY_PPAGE else 1))
        elif key in (curses.KEY_DOWN, curses.KEY_NPAGE):
            top += 10 if key == curses.KEY_NPAGE else 1
            follow = False
        elif key in (curses.KEY_END, ord("f")):
            follow = True
        elif key == ord("r"):
            refreshed = 0.0


if __name__ == "__main__":
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        sys.exit("local-ai dashboard requires an interactive terminal")
    curses.wrapper(main)
