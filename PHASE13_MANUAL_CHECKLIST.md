# Phase 13 manual LOVE verification

Automated Phase 13 coverage is run with:

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests\run.lua
```

Run the interactive checklist from the repository root with:

```powershell
& "C:\Program Files\LOVE\love.exe" .
```

For the debug-overlay check, launch with:

```powershell
& "C:\Program Files\LOVE\love.exe" . --debug
```

Record the date, operating system, LOVE version, command, and result below.
Do not mark an item as passed until it has been observed interactively.

| Check | Result |
| --- | --- |
| Menu renders and Space enters play | Pending manual verification |
| Left/Right and A/D move and clamp the paddle | Pending manual verification |
| Ball bounces from walls and paddle | Pending manual verification |
| Brick disappears and HUD count decrements | Pending manual verification |
| Missing the ball displays `Game Over` | Pending manual verification |
| Clearing all bricks displays `You win!` | Pending manual verification |
| Space returns to menu and a new play scene has 50 bricks | Pending manual verification |
| Escape quits cleanly | Pending manual verification |
| Debug overlay can inspect, switch scenes, and toggle systems | Pending manual verification |
| Focus loss/long frame does not create an excessive simulation catch-up | Pending manual verification |
| Scene switch while a movement key is held has no stale input leak | Pending manual verification |
