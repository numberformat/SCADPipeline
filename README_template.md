# Project Title

Short description of the design project.

---

## What this repo contains

- `src/models/` — OpenSCAD source files (top-level only)
- `src/assets/` — Pre-built assets (top-level only)
- `site/` — Generated viewer output (build artifact)

---

## Build

**macOS / Linux (bash):**
```bash
./build.sh
```

**Windows (PowerShell 7+):**
```powershell
./build.ps1
```

---

## Viewer

Run the local viewer:

```bash
./run.sh
```

```powershell
./run.ps1
```

Enable GitHub Pages to publish the viewer:

1. Go to **Settings** → **Pages**
2. **Source**: Deploy from a Branch
3. Select `gh-pages` and `/ (root)`
4. Save and wait for the site to publish

---

## Releases

Each build on `main` publishes STL assets as a GitHub Release.

---

## Pipeline

This project uses the SCADPipeline build system. See the pipeline README for details and updates: [SCADPipeline README](README_pipeline.md).
