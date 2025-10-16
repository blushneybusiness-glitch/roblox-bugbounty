# Deployment Guide (Railway)

1. Create a GitHub repo and push this project.
2. Sign up at https://railway.app and connect your GitHub.
3. In Railway, create a new project -> Deploy from GitHub -> select repo -> root directory: /discord-bot
4. Set Environment Variables (Railway > Variables):
   - DISCORD_TOKEN: (your bot token)
   - DISCORD_GUILD_ID: 1216754736779231243
   - MOD_ROLE_IDS: 1337921700758556682
   - BUG_CHANNEL_ID: 1363970543526744199
   - ROBLOX_SHARED_SECRET: changeme_supersecret
   - BOT_SHARED_SECRET: bot_shared_secret
   - CLOUD_API_BASE: https://<your-cloud-api> (if used)
5. Deploy. After deploy Railway gives a public URL (BASE_URL). Put that URL into Roblox Config.lua as DISCORD_PUSH_ENDPOINT.
6. In Roblox, add Server scripts to ServerScriptService and client scripts to StarterPlayerScripts. Create ReplicatedStorage/BugRemotes with RemoteEvent OpenUI and RemoteFunction SubmitReport.

Notes:
- Replace secrets with secure random strings.
- Use a proper HMAC-SHA256 implementation on Roblox for production.
