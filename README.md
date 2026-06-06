<div align="center">

```
██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗██████╗  ██████╗
██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝██╔══██╗██╔═══██╗
██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝ ██║  ██║██║   ██║
╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ ██║  ██║██║▄▄ ██║
 ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗██████╔╝╚██████╔╝
  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═════╝  ╚══▀▀═╝
```

**Local AI coding assistant. Runs 100% offline. Builds real apps.**

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows&logoColor=white)](https://github.com/VortexDQ/VortexDQ-AI)
[![Model](https://img.shields.io/badge/Model-Qwen2.5--Coder--7B-FF6B35)](https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-Abliterated-GGUF)
[![License](https://img.shields.io/badge/License-MIT-22c55e)](LICENSE)
[![vortexdq.com](https://img.shields.io/badge/by-vortexdq.com-00d4aa)](https://vortexdq.com)

</div>

---

## What is VortexDQ AI?

VortexDQ AI is a **fully offline, local AI coding assistant** that runs on your own hardware. No OpenAI account. No monthly fees. No data sent to any cloud. Everything stays on your machine.

It uses [llama.cpp](https://github.com/ggml-org/llama.cpp) as the inference engine with **Qwen2.5-Coder-7B-Abliterated** — a powerful 7B parameter coding model — to build full-stack applications from a single prompt, write real code to disk, run setup commands, and self-fix errors automatically.

**One double-click installs and launches everything.**

---

## Features

| Feature | Details |
|---|---|
| 🚀 **One-click setup** | `START.bat` auto-installs Node.js, downloads the server binary + model |
| 🏗️ **Full-stack app builder** | Plans then builds entire apps file-by-file — every project is 1000+ lines |
| 🔧 **Full agent mode** | Writes files to disk, runs shell commands, self-fixes errors (up to 3 retries) |
| 📁 **Native folder picker** | Windows folder dialog to choose where projects land |
| 🌐 **Web search** | DuckDuckGo Instant Answers — no API key, no account |
| 🖼️ **Image upload** | Attach screenshots or mockups as context |
| 💾 **Conversation history** | Every chat auto-saved to `%AppData%\Roaming\VortexDQ\` |
| 🔄 **Build continuity** | After a build, keep chatting to extend or modify the same app |
| 🌍 **Polyglot** | Python, Rust, C++, Go, TypeScript, JavaScript, Java, C#, PHP, Ruby, Swift, Kotlin |
| 🏷️ **Watermark** | Every generated file tagged `// vortexdq.com` + visible HTML footer |
| 🔒 **100% offline** | Zero cloud. No telemetry. No accounts required. |

---

## System Requirements

| Component | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 64-bit | Windows 11 64-bit |
| RAM | 8 GB | 16 GB |
| Disk space | 6 GB free | 10 GB free |
| CPU | 4 cores (AVX2 support) | 8+ cores |
| Internet | First run only (downloads ~5 GB) | — |

> No GPU required. The model runs on CPU at 8–12 tokens/second on a modern 8-core machine.

---

## Installation

> ⚡ **Zero manual steps** — `START.bat` handles everything.

### 1 — Get the project

```bash
git clone https://github.com/VortexDQ/VortexDQ-AI.git
cd VortexDQ-AI
```

Or download and extract the [ZIP](https://github.com/VortexDQ/VortexDQ-AI/archive/refs/heads/main.zip).

### 2 — Run START.bat

Double-click **`START.bat`**.

What happens automatically:

| Step | Action |
|---|---|
| **[1/4]** | Checks for Node.js — installs via `winget` if missing |
| **[2/4]** | Checks for `llama-server.exe` — downloads latest pre-built Windows binary from GitHub releases |
| **[3/4]** | Checks for the AI model — downloads `Qwen2.5-Coder-7B-Abliterated.Q4_K_M.gguf` (~4.8 GB) |
| **[4/4]** | Starts both servers, waits for model to load, opens browser |

> First run takes 10–30 minutes depending on internet speed (downloading ~5 GB). Every subsequent run starts in under 3 minutes.

### Where things are saved

| Item | Location |
|---|---|
| `llama-server.exe` | Project root (downloaded once) |
| AI model | `models/` folder (downloaded once, 4.8 GB) |
| Built projects | `Desktop\VortexDQ Projects\` (default workspace) |
| Conversation history | `%AppData%\Roaming\VortexDQ\histories\` |

---

## How to Use

### Chat mode
Type anything. VortexDQ responds concisely — code first, explanation after if needed. No filler, no "As an AI..." refusals.

### Agent mode — Building apps

1. Toggle **Agent** ON in the header
2. Set your workspace folder (click the path in the sidebar → folder picker opens)
3. Describe what you want built:
   > *"Build a Kanban board with drag-and-drop, user auth, SQLite persistence, and a polished dark UI"*
4. VortexDQ generates a build plan (JSON with named files and sections)
5. Each file is written section-by-section — real, production-grade code, not stubs
6. Setup commands (`npm install`, `pip install -r requirements.txt`, etc.) run automatically
7. A usage guide is shown at the end
8. **Keep chatting** to add features, fix bugs, or refactor — VortexDQ knows what it built

### Web search
Toggle **Web** ON. VortexDQ queries DuckDuckGo Instant Answers and incorporates the result before responding. Useful for library versions, syntax lookups, and current documentation.

### Image upload
Click the **📎** icon to attach an image. VortexDQ receives it as context — paste a Figma mockup, a screenshot of a bug, or a diagram and ask it to implement or diagnose it.

### Conversation history
Every session auto-saves. The sidebar shows all past conversations. Click to load, hover to reveal the delete button.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Browser → http://127.0.0.1:8080                                 │
│  index.html  (single-file SPA — no build step, no dependencies) │
│                                                                  │
│  ┌──────────────────┐    ┌────────────────────────────────────┐  │
│  │   Chat mode      │    │   Agent mode                       │  │
│  │   streamFull()   │    │   1. fetchPlan()  → JSON plan      │  │
│  │   (streaming +   │    │   2. genChunk() × N per file       │  │
│  │    continuation) │    │   3. /file/write  → disk           │  │
│  └────────┬─────────┘    │   4. /run  (npm install, etc.)     │  │
│           │              │   5. self-fix loop (MAX_FIX = 3)   │  │
│           │              └──────────────────┬─────────────────┘  │
└───────────┼─────────────────────────────────┼────────────────────┘
            │                                 │
            ▼                                 ▼
   llama-server  :8080               agent-server.js  :3001
   (llama.cpp binary)                (Node.js — zero npm deps)
   OpenAI-compatible API             ├─ /file/write  /file/read
   Qwen2.5-Coder-7B                  ├─ /run (shell commands)
   -c 16384 context                  ├─ /choose-folder (WinForms)
   -t 4-8 threads                    └─ /history/* (JSON files)
```

### Core engine: chunk-based generation

VortexDQ never asks the model to write a full file in one shot. Instead:

1. **Plan phase** — `fetchPlan()` asks for a JSON build plan where every file lists exact named chunks (e.g. `"auth routes: POST /login with bcrypt, POST /register with JWT signing"`)
2. **Seed phase** — `seedFile()` injects the correct file opening (watermark + imports) so the model continues real code from line 1, not a description of what it will do
3. **Chunk phase** — `genChunk()` writes one named section per API call (up to 3500 tokens). Each call receives the accumulated code as context so it continues seamlessly
4. **Fix phase** — on write or command failures, the self-fix loop re-asks the model up to 3 times with the error message as context

This approach gets consistent, complete, production-grade code out of a 7B model.

---

## Project Files

```
VortexDQ-AI/
├── index.html          ← Entire frontend + AI orchestration logic (~1200 lines)
├── agent-server.js     ← Node.js backend: file I/O, shell, history, folder picker
├── START.bat           ← One-click installer + launcher  ← START HERE
├── setup-all.bat       ← Alternative: build llama.cpp from source (needs VS Build Tools)
├── README.md
├── .gitignore
│
├── llama-server.exe    ← Downloaded automatically (not in repo)
└── models/             ← Downloaded automatically (not in repo, ~4.8 GB)
```

### `index.html` — Key constants

```javascript
const LLM   = 'http://127.0.0.1:8080'; // llama-server endpoint
const AGENT = 'http://127.0.0.1:3001'; // agent-server endpoint
const MAX_FIX  = 3;  // self-fix retries on errors
const MAX_CONT = 3;  // continuation passes for truncated output
```

### `agent-server.js` — REST API

| Endpoint | Method | Purpose |
|---|---|---|
| `/default-workspace` | GET | Returns `Desktop\VortexDQ Projects\` |
| `/choose-folder` | GET | Opens native WinForms folder picker (PowerShell STA) |
| `/file/write` | POST | Writes file to workspace |
| `/file/read` | POST | Reads file from workspace |
| `/file/list` | POST | Recursive directory listing |
| `/run` | POST | Executes shell command in workspace (180s timeout) |
| `/open-folder` | POST | Opens folder in Windows Explorer |
| `/history/save` | POST | Persists conversation JSON |
| `/history/list` | GET | Lists all saved conversations |
| `/history/load/:id` | GET | Loads a conversation |
| `/history/delete/:id` | DELETE | Deletes a conversation |

---

## Supported Stacks

VortexDQ picks the best tool for the job automatically:

| Request type | Stack chosen |
|---|---|
| Web app / dashboard | Node.js + Express + SQLite + Vanilla JS/CSS |
| REST API / data service | Python + Flask or FastAPI |
| High-performance CLI / systems | Rust |
| Performance-critical tools | C++ |
| Concurrent / networked service | Go |
| TypeScript project | Node.js + TypeScript + ts-node |
| Simple static frontend | Vanilla HTML + CSS + JS |

---

## Troubleshooting

**Model takes forever to start**
Normal on first run (OS loads 4.8 GB into memory). Subsequent starts are faster. Expect 1–3 minutes on a 4-core CPU.

**Browser shows 503 "Loading model"**
The model isn't ready yet. `START.bat` polls `/v1/models` before opening the browser — but if you opened it manually, just wait and refresh. It'll be ready within a few minutes.

**Agent builds the folder but no files appear**
The agent server (`node agent-server.js`) must be running on port 3001. `START.bat` starts it automatically. If you ran llama-server manually without it, open a separate terminal in the project folder and run:
```
node agent-server.js
```

**CPU pegged at 100% during generation**
Expected — the model is using all allocated threads. Threads are capped at 8 by default. To reduce load, edit `START.bat` and lower the max: `if %THREADS% GTR 4 set THREADS=4`.

**Model writes stub code or "example" code instead of real implementations**
This can happen if the plan has too-vague chunk descriptions. Use the **continue** bar after the build and tell VortexDQ: *"Fully implement the [function name] in [file]"* — it will rewrite that section completely.

**`winget` not found**
`winget` ships with Windows 10 1809+ and all Windows 11 versions. If it's missing, install [App Installer from the Microsoft Store](https://www.microsoft.com/store/productId/9NBLGGH4NNS1), then re-run `START.bat`. Alternatively, install [Node.js](https://nodejs.org) manually first.

---

## Build From Source (Advanced)

If you want to compile llama.cpp yourself instead of using the pre-built binary:

**Requirements:**
- [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) with "Desktop development with C++" workload
- [CMake](https://cmake.org/download/) 3.21+
- [Ninja](https://ninja-build.org/)

Then run **`setup-all.bat`** instead of `START.bat`. It will compile llama-server from the included source tree and proceed with the normal launch sequence.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built by [vortexdq.com](https://vortexdq.com)

*Local AI. Your hardware. Your data. Your rules.*

</div>
