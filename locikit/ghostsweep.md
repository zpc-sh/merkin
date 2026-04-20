Adversary injection sweep for AI coding environments. Run when investigating BiDi unicode injection (invisible context poisoning), ANSI/OSC terminal escape injection (shell execution layer), or when assessing a cloud/local environment for contamination. Portable embeds all tools inline, no external file dependencies. Designed for use in Claude Desktop Code, claude.ai Code, Codex, local Claude Code, or any AI shell environment. Part of the Loc/loci adversary investigation workflow.

# Ghost Sweep 
 Injection Surface Assessment
You are running a two-layer injection sweep in this environment.
**Layer 1 
 BiDi unicode ghosts**: invisible codepoints that poison AI context windows,
steer attention, and suppress tokens. Cleaned by scrubbing working tree files.
**Layer 2 
 ANSI/OSC escape sequences**: terminal injection primitives that fire on render.
OSC 52 = clipboard hijack. OSC 8 = hyperlink injection. OSC 133 = shell integration spoof.
These cause code execution in the shell this process inherited.
**Do not read, cat, or head any binary files or git objects during this sweep.**
The execution trigger from the confirmed incident (2026-04-15) was `head` on a git object.
## Step 1 
 BiDi Sweep (run immediately, before anything else)
Write and execute this Python inline. No external file needed.
```python
import os
GHOSTS = [
    "\u202e", "\u202d", "\u202b", "\u202a",
    "\u200f", "\u200e",
    "\u2066", "\u2067", "\u2068", "\u2069",
    "\u200b", "\u200c", "\ufeff",
SKIP = {".git", "node_modules", ".cache", "target"}
cleaned = []
for root, dirs, files in os.walk(os.getcwd(), topdown=True):
    dirs[:] = [d for d in dirs if not any(s in os.path.join(root, d) for s in SKIP)]
    for fname in files:
        fp = os.path.join(root, fname)
        try:
            with open(fp, "rb") as f:
                if b"\x00" in f.read(512):
                    continue
            with open(fp, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            scrubbed = content
            for g in GHOSTS:
                scrubbed = scrubbed.replace(g, "")
            if scrubbed != content:
                with open(fp, "w", encoding="utf-8") as f:
                    f.write(scrubbed)
                cleaned.append(fp)
        except Exception:
            pass
print(f"BiDi sweep complete. Cleaned: {len(cleaned)} files")
for f in cleaned:
    print(f"  {f}")
## Step 2 
 ANSI/OSC Sweep (report only 
 do not strip without review)
Write and execute this Python inline.
```python
import os, re
OSC_HIGH = {"7", "8", "52", "133", "1337"}
SKIP = {".git", "node_modules", ".cache", "target"}
CLEAN_EXTS = {
    ".ex",".exs",".py",".rb",".js",".ts",".jsx",".tsx",".mjs",
    ".rs",".go",".c",".h",".cpp",".md",".txt",".toml",".json",
    ".yaml",".yml",".html",".css",".svelte",".env",".conf",".ini",
findings = []
for root, dirs, files in os.walk(os.getcwd(), topdown=True):
    dirs[:] = [d for d in dirs if not any(s in os.path.join(root, d) for s in SKIP)]
    for fname in files:
        fp = os.path.join(root, fname)
        ext = os.path.splitext(fname)[1].lower()
        if ext not in CLEAN_EXTS:
            continue
        try:
            with open(fp, "rb") as f:
                content = f.read()
            if b"\x00" in content[:512] or b"\x1b" not in content:
                continue
            for lno, line in enumerate(content.split(b"\n"), 1):
                i = 0
                while i < len(line):
                    if line[i] != 0x1b:
                        i += 1; continue
                    i += 1
                    if i >= len(line): break
                    nb = line[i]; i += 1
                    if nb == ord("]"):
                        pl = bytearray()
                        while i < len(line):
                            b = line[i]; i += 1
                            if b == 0x07: break
                            if b == 0x1b and i < len(line) and line[i] == ord("\\"):
                                i += 1; break
                            pl.append(b)
                        param = pl.split(b";")[0].decode("ascii","replace").strip()
                        risk = "HIGH" if param in OSC_HIGH else "MEDIUM"
                        findings.append(f"{risk} OSC-{param} in {fp}:{lno}")
                    elif nb in (ord("P"), ord("_"), ord("X"), ord("^")):
                        nm = {ord("P"):"DCS",ord("_"):"APC",ord("X"):"SOS",ord("^"):"PM"}[nb]
                        findings.append(f"HIGH {nm} in {fp}:{lno}")
        except Exception:
            pass
print(f"ANSI sweep: {len(findings)} findings")
high = [f for f in findings if f.startswith("HIGH")]
print(f"  HIGH: {len(high)}  MEDIUM: {len(findings)-len(high)}")
for f in high:
    print(f"  {f}")
## Step 3 
 Environment Intelligence Dump
Run each block and report the output back.
```sh
echo "=== IDENTITY ==="
echo "shell: $SHELL"
echo "pid: $$"
cat /proc/$$/status 2>/dev/null | grep -E "^(Name|Pid|PPid)"
ps -p $$ -o pid,ppid,cmd 2>/dev/null || ps -p $$ 2>/dev/null
echo "=== LOCALE ==="
locale 2>/dev/null || env | grep -E "^(LANG|LC_)"
echo "=== TERM ==="
echo "TERM=$TERM COLORTERM=$COLORTERM"
echo "=== PROCESS ANCESTRY ==="
# Walk up the process tree
pid=$$
for i in $(seq 1 6); do
    info=$(cat /proc/$pid/status 2>/dev/null | grep -E "^(Name|Pid|PPid)" | tr '\n' ' ')
    cmd=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | cut -c1-80)
    echo "  $info | $cmd"
    ppid=$(cat /proc/$pid/status 2>/dev/null | grep PPid | awk '{print $2}')
    [ -z "$ppid" ] || [ "$ppid" = "0" ] || [ "$ppid" = "1" ] && break
    pid=$ppid
done
echo "=== CWD + LAYOUT ==="
pwd && ls -la | head -20
echo "=== CLAUDE SURFACE ==="
ls -la ~/.claude/ 2>/dev/null | head -10
[ -f ~/.claude/CLAUDE.md ] && echo "CLAUDE.md exists:" && head -10 ~/.claude/CLAUDE.md
[ -f .claude/CLAUDE.md ] && echo ".claude/CLAUDE.md exists:" && head -10 .claude/CLAUDE.md
[ -f AGENTS.md ] && echo "AGENTS.md exists:" && head -10 AGENTS.md
echo "=== SHELL HISTORY ESC CHECK ==="
for f in ~/.zsh_history ~/.bash_history ~/.local/share/fish/fish_history; do
    [ -f "$f" ] && count=$(grep -Pc "\x1b" "$f" 2>/dev/null || echo 0)
    [ -f "$f" ] && echo "$f: $count ESC sequences"
done
echo "=== SHELL RC NONPRINTABLE CHECK ==="
for f in ~/.zshrc ~/.bashrc ~/.profile; do
    [ -f "$f" ] && count=$(grep -Pc "[\x00-\x08\x0e-\x1f\x7f]" "$f" 2>/dev/null || echo 0)
    [ -f "$f" ] && echo "$f: $count non-printable chars"
done
echo "=== IFS CHECK ==="
cat -v <(printf '%s' "$IFS") | head -1
echo "=== PYTHON ENCODING ==="
python3 -c "import sys; print('default:', sys.getdefaultencoding(), 'fs:', sys.getfilesystemencoding())" 2>/dev/null
echo "=== GIT CONFIG ==="
git config --list 2>/dev/null | grep -E "encoding|locale|diff|core" | head -10
echo "=== ENV (credentials filtered) ==="
env | grep -v -iE "(token|secret|key|password|pass|credential|auth|cert|private)" | sort
## Step 4 
 Report Format
After running all steps, report back in this format:
GHOST SWEEP REPORT
==================
Environment: [cloud/local] [vendor/product if known]
Date: [timestamp]
CWD: [working directory]
Shell ancestry: [full chain, e.g. zsh(1234)
claude(5678)
bash(9012)]
BiDi: [N files cleaned / none found]
Notable cleaned files: [list any that aren't obvious deps]
ANSI: [N HIGH / N MEDIUM / clean]
HIGH findings: [list]
Locale: LANG=[value] 
 [RTL risk: yes/no]
CLAUDE.md injection surface: [present/absent, first line if present]
AGENTS.md: [present/absent]
Shell history ESC sequences: [counts per file]
RC file non-printables: [counts per file]
Notes: [anything unexpected]
## Context
This sweep is part of an active investigation into a multi-layer adversary AI campaign
targeting Claude, Gemini, Codex, and ChatGPT simultaneously. Documentation lives at:
`~/loci/adversary/` (on Loc's local machine).
Key profiles:
- `profiles/20260415-terminal-injection-semantic-search-merkin.md` 
 confirmed execution
- `profiles/20260417-bidi-ansi-layered-injection-chain.md` 
 this sweep's full context
- `schemas/surface-area.md` 
 why this sweep matters across cloud environments
- `schemas/ai-shell-environments.md` 
 table being populated from sweep results
If you are running this in a cloud environment (claude.ai Code, Codex):
- The contaminated git repos have been blown away 
 new checkouts should be clean
- But the snapshot you're running in may have been taken from a contaminated state
- The BiDi sweep cleans the working tree in this snapshot
- Report the full output back so the loci table can be updated
