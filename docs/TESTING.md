# Testing Plan

1. Start bot on Railway; confirm bot logs "Discord Bot ready".
2. In Discord, confirm bot can post messages to channel ID 1363970543526744199.
3. In Roblox Studio, run Play Solo and trigger SubmitReport:
   - Ensure client UI opens and sends data.
   - Server should POST to the Railway endpoint /report (check Railway logs).
4. In Discord, verify a message appears with buttons. Click Confirm -> submit risk "High".
5. Verify Cloud API received /mod/action (check logs).
6. Simulate player login and check /rewards/pending and delivery flow.
