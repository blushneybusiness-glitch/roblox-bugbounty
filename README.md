# Roblox Bug-Bounty System (Railway-ready)

This package contains:
- `roblox/` — Roblox client & server scripts (TopbarPlus UI, report handling)
- `discord-bot/` — Node.js Discord bot + Express endpoints (ready for Railway)
- `docs/` — deployment, Railway setup, testing guides

Pre-filled IDs (please set your secrets in env):
- DISCORD_GUILD_ID=1216754736779231243
- MOD_ROLE_IDS=1337921700758556682
- BUG_CHANNEL_ID=1363970543526744199

**Important:** Replace all placeholder secrets (`ROBLOX_SHARED_SECRET`, `DISCORD_TOKEN`, etc.) with real values in Railway environment variables.

See `docs/RAILWAY_SETUP.md` for step-by-step deployment instructions.
