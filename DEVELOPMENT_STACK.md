<!-- DEVELOPMENT_STACK.md -->
# BagIdea Office Development Stack

เอกสารนี้สรุปว่าโปรเจกต์ BagIdea Office ใช้อะไรบ้างในการพัฒนา แต่ละส่วนมีหน้าที่อะไร ใช้ไปเพื่ออะไร และผลลัพธ์ที่ส่วนนั้นสร้างให้กับระบบคืออะไร

## ภาพรวม

BagIdea Office เป็น desktop AI office ที่ทำงานเหมือนโลกจำลอง 2.5D บน wallpaper ของเครื่อง ผู้ใช้คุยกับ Director และ agents ผ่าน overlay, CLI, voice, channels หรือ plugins จากนั้น daemon จะสั่งงาน agent ผ่าน Codex CLI และส่ง event ให้ Godot world แสดงผลเป็นตัวละครเดิน ทำงาน ประชุม ขออนุญาต และรายงานผล

## Core Runtime

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| Codex CLI | รัน agent แบบ headless ผ่าน `codex exec --json` และ resume thread ผ่าน `codex exec resume` | เป็น AI runtime หลักที่ทำงานจริงใน workspace หรือ project folder | คำตอบ agent, tool progress, resumable sessions, JSONL events ที่ daemon แปลงเป็น office events |
| Node.js 18+ | รัน daemon ที่ `daemon/server.js` | เป็นศูนย์กลางของระบบ ทำ API, WebSocket, registry, sessions, plugins, media และ routing งาน | HTTP API ที่ port `8787`, WebSocket `/ws`, `journal.jsonl`, `registry.json`, `sessions.json` |
| Godot 4.6+ | render โลก 2.5D office | แสดงสถานะจริงของ agents เป็น wallpaper world ไม่ใช่ dashboard ธรรมดา | office floor, rooms, agents, FX, nameplates, map, day/night cycle, editor world |
| Rust | สร้าง shell desktop app ใน `shell/` | รวม daemon + Godot + tray + chat head + wallpaper embedding เป็นโปรแกรมเดียว | `bagidea-office-shell.exe`, tray app, chat head, wallpaper integration |
| PowerShell | automation ฝั่ง Windows | คุม launcher, hooks เดิม, project windows, wallpaper tools, installer/update scripts | install/update commands, project window control, dev helper scripts |

## User Interfaces

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| HTML/CSS/JavaScript overlay | UI หลักที่ daemon serve จาก `daemon/overlay.html` | ให้ผู้ใช้คุยกับ agents, ตั้งค่า, จัดการ projects, plugins, channels, keys, models และดู stats | Web overlay, settings panels, chat UI, project controls, plugin windows |
| Godot UI/HUD | UI ในโลก wallpaper | ทำให้ activity ของ agents เห็นเป็นสิ่งมีชีวิตใน office | nameplates, task board, whiteboard, event FX, camera focus |
| Static website ใน `web/` | landing page และ browsable docs | อธิบาย product และ deploy เป็นเว็บแบบ static ได้ | `web/index.html`, `web/docs.html`, `web/plugins.html`, sponsor pages |
| CLI `bagidea` | command line control | ให้สั่งงาน office จาก terminal ได้เร็ว เช่น start, stop, ask, status, update | `bagidea` command, `bagidea.cmd`, CLI output และ daemon API calls |

## Data And State

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| `daemon/registry.json` | เก็บ roster, roles, skills, tools, API keys, provider config, channels | ทำให้ office จำทีมและการตั้งค่าหลัง restart | persistent agent registry และ settings |
| `daemon/sessions.json` | เก็บ thread metadata และ chat history แบบย่อ | ทำให้ agent conversation ต่อเนื่องและ resume ได้ | named sessions, visible history, Codex thread ids |
| `daemon/journal.jsonl` | เก็บ event stream | ให้ renderer/overlay replay state หลัง restart หรือ reconnect | event replay สำหรับ Godot และ overlay |
| `workspace/` | พื้นที่ทำงานกลางของ agents | ให้ agents มี notes, memory และไฟล์กลางที่อ่าน/เขียนร่วมกันได้ | `notes.md`, `OFFICE.md`, memory files, generated outputs |
| Project folders | โฟลเดอร์จริงที่ user register เป็น project | ให้ agents ทำงานใน path จริงและผู้ใช้ resume งานต่อได้ | code/files ของ project, session-bound work, project status |

## Agent And Office Features

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| Agent registry | กำหนด persona, role, avatar, aura, tools, skills, provider/model | ทำให้แต่ละ agent มีตัวตนและหน้าที่ชัด | agents เช่น Director, staff, CEO avatar |
| Skills library | เก็บชุด instruction ที่ assign ให้ agents | เพิ่มความสามารถเฉพาะทาง เช่น research, code review, plugin building | skill definitions และ prompt context สำหรับ Codex sessions |
| Delegation protocol | ใช้บรรทัด `DELEGATE:` เพื่อส่งงานต่อให้ agent | ให้ Director บริหารทีมแทนทำเองทุกอย่าง | child agent tasks, report-back flow, CEO summary |
| Sub-agent protocol | ใช้บรรทัด `SUB:` เพื่อแตกงานย่อย | ทำงาน parallel เมื่อโจทย์แบ่งย่อยได้ | ghost sub-agent sessions และ final synthesis |
| Project protocol | ใช้ `PROJECT:` และ `DELEGATE: <agent> @ <project>` | สร้าง/ผูกงานกับ project folder จริง | registered projects และ work inside project directories |
| Permission/Security flow | แสดง approval card เมื่อเจอ action ที่ต้องขออนุญาต | ให้ agent work มี human control | permission requests, allow/deny decisions, forever grants |

## Integrations

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| Telegram/Discord/LINE channels | ต่อข้อความจากภายนอกเข้า Director | ให้สั่งงาน office จากมือถือหรือ chat platform ได้ | inbound channel messages และ outbound replies |
| OpenAI API | ใช้กับ voice/image/Codex auth หรือ key injection ตาม feature | ปลดล็อกเสียง รูปภาพ และ runtime capability ที่ต้องใช้ OpenAI | transcription, image generation, environment keys |
| Gemini API | ใช้กับ voice/TTS/realtime fallback ตาม feature | เพิ่ม voice และ realtime interaction | transcription fallback, TTS/realtime voice |
| Plugin host | โหลด plugins จาก `plugins/` | ขยาย office ด้วย panel, routes และ commands | plugin UI, server routes, agent-driveable commands |
| MCP metadata | เก็บ capability server commands ใน registry | รองรับแนวคิด tool extension และ compatibility กับ tool ecosystem | MCP config metadata และ assignable tool entries |

## Build, Install, And Release

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| `package.json` | รวม npm scripts เช่น `npm run dev` | ให้ developer เริ่ม daemon ได้ด้วย workflow มาตรฐาน Node | `npm run dev` -> `node daemon/server.js` |
| Cargo/Rust toolchain | build shell | ทำ desktop executable สำหรับ Windows/macOS | release binary ใต้ `shell/target/release/` |
| Installer scripts | ติดตั้ง dependency และ wire command | ให้ user ติดตั้งง่ายบนเครื่องใหม่ | install/update flow, shortcut/PATH setup |
| `VERSION` + updater | ตรวจ version และ update จาก repo | ให้ app self-update ได้ | update banner, `bagidea update`, rebuild/relaunch |
| GitHub Actions/Sponsors files | sync sponsor info และ release support | ทำเว็บ/README sponsor wall และ release process | generated sponsor JSON/README block |

## Visual Assets

| ส่วนที่ใช้ | ใช้ทำอะไร | เพื่ออะไร | สร้างอะไร |
|---|---|---|---|
| Pixel-art sprites | ตัวละคร agents และ ambient life | ทำให้ office มี character presence | agent sprites, cat/dog/bird animations |
| Godot scenes/assets | ห้อง เฟอร์นิเจอร์ ฉาก countryside FX | ทำให้ wallpaper เป็นโลกจริงที่ rearrange ได้ | 3x3 room grid, Ghost Deck, meeting room, server room |
| Images in `docs/img` and `web/img` | ใช้ใน README/website/docs | อธิบาย product ด้วยภาพจริง | screenshots, landing visuals, sponsor images |
| Audio/TTS assets | เสียงพูดและ sound effects | เพิ่มความมีชีวิตให้ office | agent voice playback, event audio |

## Important Outputs

- Desktop wallpaper world: render โดย Godot และควบคุมผ่าน Rust shell
- Office daemon: Node.js server ที่ port `8787`
- Agent runs: Codex CLI sessions ที่ทำงานใน `workspace/` หรือ project folder
- Web overlay: UI สำหรับ chat/settings/projects/plugins
- CLI: `bagidea` command สำหรับควบคุม office
- Runtime state: registry, sessions, journal, notes, memory และ project metadata
- Website/docs: static files ใน `web/` และ markdown docs ใน `docs/`

## Developer Entry Points

```powershell
npm run dev
```

รัน daemon แบบ development ผ่าน Node.js

```powershell
node daemon\server.js
```

รัน daemon ตรง ๆ โดยไม่ผ่าน npm

```powershell
.\shell\target\release\bagidea-office-shell.exe
```

รัน full desktop shell หลัง build แล้ว

```powershell
bagidea status
bagidea ask "Hello"
```

ทดสอบ CLI ที่คุยกับ daemon
