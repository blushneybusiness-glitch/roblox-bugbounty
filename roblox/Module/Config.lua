-- Config.lua
return {
  DISCORD_PUSH_ENDPOINT = "https://<your-railway-url>.up.railway.app/report",
  SHARED_SECRET = "changeme_supersecret",
  BUG_CHANNEL_ID = "1363970543526744199",
  USE_OPEN_CLOUD = false,
  BASE_REWARD = { Low=50, Medium=150, High=500, Critical=1500 },
  RANK_MULTIPLIERS = { Tier1=1, Tier2=2, Tier3=3 },
  RANK_THRESHOLDS = {
    Tier2 = { Medium=3, High=2 },
    Tier3 = { Critical=1, High=3 }
  },
  GROUP_SETTINGS = {
    ENABLE_AUTO_RANK = false,
    GROUP_ID = 0,
    ROLE_IDS = {}
  }
}
