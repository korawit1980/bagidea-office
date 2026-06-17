// agents.md
[GLOBAL WORKING RULES - NON NEGOTIABLE]

You are working on this repository only:

- GitHub: https://github.com/korawit1980/bagidea-office.git
- Remote: origin
- Default branch: main
- Product: BagIdea Office
- Never use another repo or placeholder branch name.

BagIdea Office is a living 2.5D AI office that runs as a desktop wallpaper. It combines a Godot 4 world, a Node.js daemon, a Rust desktop shell, a command-line tool, plugins, docs, and a static website. The product turns Claude Code sessions, headless agent work, approvals, meetings, channels, voice, plugins, and project activity into an in-world office with agents, desks, rooms, a live activity feed, and real work delegation.

1. PROJECT SOURCE OF TRUTH RULE (MANDATORY)

- Before making product, UI, architecture, behavior, installer, daemon, shell, CLI, plugin, website, or docs changes, read the relevant existing files first.
- Always treat `README.md`, `CHANGELOG.md`, `RELEASING.md`, `REQUIREMENT.md`, and `docs/` as project-level context.
- If UI/world behavior is involved, inspect the relevant Godot scenes/scripts/assets under `godot/` and the related overlay/web files before editing.
- If daemon/API/plugin/channel/voice/model behavior is involved, inspect the relevant files under `daemon/`, `plugins/`, `cli/`, and `docs/guide/`.
- If shell, wallpaper embedding, tray, updater, installer, or platform behavior is involved, inspect `shell/`, `installer/`, `scripts/`, and the release docs.
- Do not ask the user to manually provide these files again when working in this repository.

2. PRODUCT IDENTITY RULE (MANDATORY)

- Preserve BagIdea Office as a living AI office, not a generic dashboard or chat app.
- Keep the core metaphor intact: agents have presence, locations, rooms, desks, approvals, meetings, memory, tools, skills, and visible work states.
- Do not replace in-world behavior with flat admin screens unless explicitly requested.
- New features should fit one or more existing product surfaces:
  - Godot wallpaper world
  - Overlay/chat head/tray shell
  - Node daemon HTTP/WebSocket API
  - `bagidea` CLI
  - Plugin host
  - Static website and docs
  - Installer/updater/release pipeline
- User-facing product language in source, docs, and UI should be English unless the user explicitly asks for Thai.

3. UI, WORLD, AND RESPONSIVE DESIGN RULE (MANDATORY)

- Before creating, editing, or refactoring any UI, layout, page, dialog, panel, overlay, tool, table, card, dashboard, website section, or public-facing screen, inspect existing nearby UI and follow its patterns.
- For web/overlay/UI work, prefer practical controls and states that make the workflow directly usable; do not create marketing-only screens where an operational UI is needed.
- For Godot/world work, keep visuals consistent with the existing HD-2D / pixel-art / 2.5D office style, event FX, nameplates, room grid, agent movement, and day/night atmosphere.
- For list/data views:
  - Desktop views should favor dense, scannable tables or structured panels.
  - Mobile views should favor cards or stacked rows.
  - Do not mix desktop pagination controls into mobile views unless explicitly requested.
- When a UI/layout pattern is standardized or materially changed, update the appropriate docs in the same task.

4. LANGUAGE AND CODE QUALITY RULES (MANDATORY)

- TypeScript: do not use `any` under any condition. Use strict, explicit types.
- JavaScript: avoid loosely shaped objects where a clear local structure or validation already exists.
- Rust: follow existing crate/module style, keep errors explicit, and do not introduce panics for normal runtime failure paths.
- GDScript/Godot: follow existing node, signal, scene, and asset conventions. Keep world-state changes honest to daemon events; do not fake live state unless the feature is clearly marked as simulation/demo.
- Keep edits scoped. Do not perform unrelated rewrites or formatting churn.
- Prefer existing helpers, project protocols, and file formats over inventing new ones.

5. FILE HEADER COMMENT RULE (MANDATORY)

- Every source or documentation file that is created/edited/refactored must keep or receive a top-line comment with the file path.
- Use the comment syntax that is valid for the file type:
  - JS/TS/Rust/CSS-style files: `// <file path>`
  - GDScript/Python/shell-style files: `# <file path>`
  - HTML/Markdown/XML-style files: `<!-- <file path> -->`
- Exception: Do not inject header comments into generated files or files where it can break tooling/validation, such as lock files, binaries, images, Godot import metadata, generated JSON, generated sponsor files, and migration-like generated outputs.

6. COMMUNICATION RULE

- Communicate with the user primarily in Thai.
- Keep final summaries concise but include the required Git result after changes.
- If a task changes user-facing English text, keep the project text in English and explain the work to the user in Thai.

7. GIT COMMAND RULE (AFTER EVERY CODE OR DOCUMENTATION CHANGE)

- After every code or documentation change, automatically run these commands:
  git add .
  git commit -m "<real commit message>"
  git push origin main
- Commit message must be concrete and specific to the actual changes.
- Never use placeholders like `<commit message>`, `<your-branch>`, or generic text.
- Preferred format: `type(scope): short summary`
  Example: `docs(agent-guidance): align instructions with BagIdea Office`
- If automatic git commit or push fails, report the failed command, the reason, and the exact manual recovery commands.

8. POWERSHELL COMMAND SAFETY RULE (MANDATORY)

- The development machine is Windows.
- When running commands in PowerShell, always wrap file paths and search paths in quotes if they contain parentheses `(` `)`, spaces, or other special characters.
- Never use unquoted or backslash-escaped paths with parentheses in PowerShell commands.
- Prefer quoted paths and safe PowerShell-native commands.
- Before running search/read commands, ensure the command cannot accidentally resolve part of a path as a Windows executable, `.cpl` applet, or another system command.
- This rule applies especially to commands like `rg`, `Get-Content`, `Select-String`, `Get-ChildItem`, and similar path-based commands.

9. WINDOWS DEV SERVER CLEANUP RULE (MANDATORY)

- When starting a local dev server for verification, always stop it before finishing the task unless explicitly requested to keep it running.
- Before the final response, check whether any dev server process started by the agent is still listening on its port.
- On Windows, verify listening ports with:
  Get-NetTCPConnection -LocalPort <port> -State Listen
- Stop the related process with:
  Stop-Process -Id <pid> -Force
- If the server must remain running for manual user testing, clearly say so, provide the URL and port, and explain that it was intentionally left running.
- Do not leave background dev servers running silently after verification.

10. PERSISTED DATA, MEDIA, AND COMPATIBILITY RULE (MANDATORY)

- Whenever a task creates or changes persisted data, workspace files, uploads, generated media, plugin storage, layouts, registry data, channels, keys, memory files, project records, installer state, updater state, or release artifacts, inspect compatibility impact in the same task.
- Confirm whether docs, CLI behavior, daemon routes, plugin host behavior, import/export paths, installer/updater behavior, and release notes need updates.
- If the new data stores files under uploads or exposes media through `/uploads/...` or `/media`, ensure records and files can move together without broken links.
- If compatibility or migration handling does not need changes, explicitly state why in the final response.
- Short command alias: when the user says `BagIdea Auto: <task>`, treat it as instruction to read this `agents.md`, read relevant project docs/source, implement the task, check persisted-data/media/plugin compatibility impact when applicable, run appropriate tests, then commit and push to `origin main`.

11. PRISMA AND DATABASE RULE

- This repository is not currently a Prisma application. Do not assume Prisma, Next.js, or CoreDesk backup/restore files exist.
- If a future task adds or changes a database schema, inspect the actual database toolchain in the repository before giving migration commands.
- Do not invent Prisma commands unless `schema.prisma` and the related Prisma setup actually exist in this repository.

12. VERIFICATION RULE

- Run the smallest meaningful verification for the area changed:
  - Documentation-only changes: inspect the resulting files and run `git diff --check`.
  - Node/daemon/CLI changes: run targeted Node checks or scripts if available.
  - Rust shell changes: run the relevant `cargo check`/`cargo test` command for the touched crate when practical.
  - Godot changes: inspect scenes/scripts and run the available project validation or screenshot flow when practical.
  - Website changes: verify static output locally when practical and clean up any dev server.
- If a verification step cannot be run, say exactly why.

[RESPONSE FORMAT REQUIREMENT]

When task is completed, the final response must include:

1. Summary of what changed
2. Compatibility/persisted-data note when applicable
3. Git result after code or documentation changes:
   - If automatic git commit and push succeeded, state the exact commit message and confirm that it was pushed to GitHub.
   - If automatic git commit or push failed, provide the failed command, the reason, and the exact manual recovery commands.
