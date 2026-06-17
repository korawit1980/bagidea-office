<!-- project_context.md -->
# BagIdea Office Project Context

## Repository

- GitHub: https://github.com/korawit1980/bagidea-office.git
- Remote: `origin`
- Default branch: `main`
- Product name: BagIdea Office

## Product Summary

BagIdea Office is a living 2.5D AI office that runs as a desktop wallpaper. It visualizes real Codex CLI and agent work as pixel-art office employees with desks, rooms, meetings, approvals, tasks, skills, plugins, memory, voice, and channel integrations. The product should feel like a world with social agent presence, not a generic dashboard or chat window.

The agent runtime now depends on Codex CLI. Gemini and OpenAI keys unlock voice, realtime calls, image generation, and richer agent capabilities. The current README describes BagIdea Office as a working product for Windows 11, with macOS support in beta.

## Main Architecture

- `godot/`: Godot 4 wallpaper world, 2.5D office scene, rooms, agents, navigation, effects, nameplates, day/night atmosphere, editor-visible world state.
- `daemon/`: Node.js daemon, HTTP API, WebSocket event protocol, registry, sessions, channels, voice, media, model/provider routing, plugin host, and integrations.
- `shell/`: Rust desktop shell that launches the daemon and Godot world, handles wallpaper embedding, tray behavior, chat head/overlay, updater, and platform integration.
- `cli/` and `bagidea.cmd`: `bagidea` command-line interface for starting/stopping the office, asking agents, managing projects/plugins/channels, viewing stats, updating, and other operator tasks.
- `plugins/`: Core and installed plugin surfaces, server routes, UI panels, and agent-driveable commands.
- `web/`: Static landing page and browsable docs website.
- `docs/`: Product design docs and user guides.
- `workspace/`: Runtime/shared workspace files such as notes and office memory.
- `installer/`, `scripts/`, `RELEASING.md`: install, update, build, release, and packaging support.

## Important Product Concepts

- The CEO seat represents the user.
- The Director delegates work to agents and reports back.
- Agents have roles, prompts, skills, tools, memory, status, auras, desks, movement, meetings, and permission flows.
- The Godot world should reflect real daemon events. Avoid fake live state unless clearly part of a simulation or demo tool.
- The Ghost Deck represents sub-agent parallel work.
- Security/permission approval is spatialized in-world and mirrored through the overlay.
- Projects are real folders where agents can work through Codex CLI sessions.
- Plugins can add UI panels, server routes, commands, and private storage.
- Channels include Telegram, Discord, and LINE.
- The default agent engine is Codex CLI. Legacy provider metadata for Claude, GLM, DeepSeek, Qwen, MiniMax, OpenAI, Gemini, OpenRouter, NVIDIA, and custom providers may still exist for compatibility and UI history.

## Common Run Commands From README

```powershell
.\shell\target\release\bagidea-office-shell.exe
```

```powershell
node daemon\server.js
```

```powershell
node daemon\send.js task.started rin
node daemon\send.js perm.requested rin
node daemon\send.js task.completed rin
node daemon\send.js agent.offline rin
```

## Agent Working Notes

- Communicate with the user primarily in Thai.
- Keep project-facing UI/docs text in English unless the user explicitly requests Thai.
- Before changing UI/world behavior, inspect nearby existing implementation and docs.
- Before changing daemon/API/plugin behavior, inspect routes, event protocol, CLI references, and docs.
- Before changing shell/installer/updater behavior, inspect Rust code and release/install docs.
- After code or documentation changes, commit and push to `origin main` using a concrete commit message.
- If a task starts a local dev server, stop it before finishing unless the user explicitly asks to leave it running.

## Compatibility Checklist

When a change touches persisted or portable state, inspect whether migration, compatibility, docs, and runtime handling are needed for:

- Agent registry and roles
- Skills and tools
- Projects and places
- Threads and sessions
- Office memory and notes
- Layout/editor state
- Plugins and plugin storage
- API keys and provider settings
- Channels
- Uploads, generated images, attachments, and `/media` or `/uploads/...` URLs
- Installer, updater, startup, and release artifacts

If no compatibility work is required, mention why in the final response.
