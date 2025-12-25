ユーザーは日本語ネイティブなので日本語でやり取りを行ってください。

# Repository Guidelines

## Project Structure & Module Organization
Current structure:
- `assets/screenshots/` for captured images (PNG is ignored in Git).
- `scripts/` for setup and device tooling.
- `README.md` for usage.

## Build, Test, and Development Commands
No build or test commands are defined yet. Current tooling commands:
- `scripts/setup.sh` (check/install dependencies)
- `scripts/run_scrcpy.sh` (start scrcpy)
- `scripts/screenshot.sh` (capture screenshot)
- `scripts/auto_swipe.sh` (auto screenshot + swipe loop)
- `scripts/trim_manga.sh` (trim screenshots)
- `scripts/pngs_to_pdf.sh` (pngs to pdf)
- `scripts/remove_last3.sh` (remove last 3 pngs)
- `scripts/run_all.sh` (auto swipe -> remove last3 -> trim -> pdf)

## Coding Style & Naming Conventions
No style configuration is present yet. When you add formatting or linting tools, document:
- Indentation (e.g., 2 spaces or 4 spaces).
- File naming (e.g., `snake_case.py`, `kebab-case.ts`).
- Formatter/linter commands (e.g., `ruff`, `prettier`, `go fmt`).

## Testing Guidelines
No testing framework is configured yet. Once you add tests:
- State the framework (e.g., `pytest`, `jest`, `go test`).
- Note test file naming (e.g., `test_*.py`, `*.spec.ts`).
- Include the exact command to run tests locally.

## Commit & Pull Request Guidelines
No Git history is available in this workspace, so commit conventions are unknown. Until conventions emerge:
- Use concise, present-tense commit messages (e.g., “Add screenshot capture script”).
- For PRs, include a short summary, linked issue (if applicable), and screenshots for UI changes.

## Agent-Specific Instructions
- Keep this document updated when tooling or structure changes.
- Prefer small, focused changes with clear commit history.
