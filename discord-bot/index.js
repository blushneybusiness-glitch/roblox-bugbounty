// index.js - Discord bot + Express endpoints
// Environment variables (set in Railway):
// DISCORD_TOKEN, DISCORD_GUILD_ID, MOD_ROLE_IDS, BUG_CHANNEL_ID,
// ROBLOX_SHARED_SECRET, BOT_SHARED_SECRET, CLOUD_API_BASE

import 'dotenv/config';
import express from 'express';
import bodyParser from 'body-parser';
import axios from 'axios';
import crypto from 'crypto';
import { Client, GatewayIntentBits, Partials, ActionRowBuilder, ButtonBuilder, ButtonStyle, ModalBuilder, TextInputBuilder, TextInputStyle, EmbedBuilder, Events } from 'discord.js';

const CONFIG = {
  TOKEN: process.env.DISCORD_TOKEN,
  MOD_ROLE_IDS: (process.env.MOD_ROLE_IDS || "1337921700758556682").split(',').filter(Boolean),
  PORT: process.env.PORT || 4000,
  BOT_SHARED_SECRET: process.env.BOT_SHARED_SECRET || "bot_shared_secret",
  CLOUD_API_BASE: process.env.CLOUD_API_BASE || (process.env.BASE_URL || "http://localhost:3000"),
  GUILD_ID: process.env.DISCORD_GUILD_ID || "1216754736779231243",
  CHANNEL_ID: process.env.BUG_CHANNEL_ID || "1363970543526744199"
};

function sign(payload, secret) {
  const ts = Math.floor(Date.now() / 1000).toString();
  const bodyStr = JSON.stringify(payload);
  const signature = crypto.createHmac('sha256', secret).update(ts + "." + bodyStr).digest('hex');
  return { signature, ts };
}

// Discord client
const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages],
  partials: [Partials.Channel],
});

client.once('ready', () => {
  console.log('Discord Bot ready', client.user.tag);
});

client.on(Events.InteractionCreate, async (interaction) => {
  try {
    if (interaction.isButton()) {
      const member = interaction.member;
      if (!member.roles || !CONFIG.MOD_ROLE_IDS.some(id => member.roles.cache.has(id))) {
        await interaction.reply({ content: "You are not allowed to moderate.", ephemeral: true });
        return;
      }
      const [action, caseId] = interaction.customId.split("::");
      if (action === "confirm") {
        const modal = new ModalBuilder()
          .setCustomId("confirm_modal::" + caseId)
          .setTitle("Confirm Bug - " + caseId);

        const riskInput = new TextInputBuilder()
          .setCustomId("risk_level")
          .setLabel("Risk (Low/Medium/High/Critical)")
          .setStyle(TextInputStyle.Short)
          .setPlaceholder("High")
          .setRequired(true);

        const notesInput = new TextInputBuilder()
          .setCustomId("notes")
          .setLabel("Notes (optional)")
          .setStyle(TextInputStyle.Paragraph)
          .setRequired(false);

        const row1 = new ActionRowBuilder().addComponents(riskInput);
        const row2 = new ActionRowBuilder().addComponents(notesInput);
        modal.addComponents(row1, row2);
        await interaction.showModal(modal);

      } else if (action === "decline") {
        const modal = new ModalBuilder()
          .setCustomId("decline_modal::" + caseId)
          .setTitle("Decline Bug - " + caseId);

        const reasonInput = new TextInputBuilder()
          .setCustomId("decline_reason")
          .setLabel("Reason")
          .setStyle(TextInputStyle.Paragraph)
          .setRequired(true);

        modal.addComponents(new ActionRowBuilder().addComponents(reasonInput));
        await interaction.showModal(modal);
      }
    } else if (interaction.isModalSubmit && interaction.isModalSubmit()) {
      // new API: check using isModalSubmit is not a function in v14; using type check below
    } else if (interaction.isModalSubmit && interaction.customId) {
      // placeholder; actual modal handling is below in 'interactionCreate' via modal submit handling
    }
  } catch (err) {
    console.error("Interaction handler error:", err);
  }
});

// Modal submit handling
client.on(Events.InteractionCreate, async (interaction) => {
  try {
    if (!interaction.isModalSubmit()) return;
    const parts = interaction.customId.split("::");
    const modalType = parts[0];
    const caseId = parts[1];
    if (modalType === "confirm_modal") {
      const risk = interaction.fields.getTextInputValue("risk_level");
      const notes = interaction.fields.getTextInputValue("notes");
      const payload = { caseId, action: "accept", modId: interaction.user.id, modName: interaction.user.username, reasonOrRisk: risk, notes };
      const { signature, ts } = sign(payload, process.env.ROBLOX_SHARED_SECRET || "changeme_supersecret");
      try {
        await axios.post((CONFIG.CLOUD_API_BASE || "") + "/mod/action", payload, {
          headers: { "X-Timestamp": ts, "X-Signature": signature }
        });
        await interaction.reply({ content: `Marked accepted (${risk}) for ${caseId}`, ephemeral: true });
      } catch (err) {
        console.error(err);
        await interaction.reply({ content: "Failed to update case: " + err.message, ephemeral: true });
      }
    } else if (modalType === "decline_modal") {
      const reason = interaction.fields.getTextInputValue("decline_reason");
      const payload = { caseId, action: "decline", modId: interaction.user.id, modName: interaction.user.username, reasonOrRisk: reason, notes: "" };
      const { signature, ts } = sign(payload, process.env.ROBLOX_SHARED_SECRET || "changeme_supersecret");
      try {
        await axios.post((CONFIG.CLOUD_API_BASE || "") + "/mod/action", payload, {
          headers: { "X-Timestamp": ts, "X-Signature": signature }
        });
        await interaction.reply({ content: `Marked declined for ${caseId}`, ephemeral: true });
      } catch (err) {
        await interaction.reply({ content: "Failed to update case: " + err.message, ephemeral: true });
      }
    }
  } catch (err) {
    console.error("Modal handling error:", err);
  }
});

client.login(CONFIG.TOKEN);

// Express endpoint
const app = express();
app.use(bodyParser.json({ limit: '200kb' }));

function verifyCloudSignature(signature, ts, body) {
  const expected = crypto.createHmac('sha256', process.env.BOT_SHARED_SECRET || "bot_shared_secret").update(ts + "." + JSON.stringify(body)).digest('hex');
  try {
    return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(signature, 'hex'));
  } catch (e) {
    return false;
  }
}

app.post('/incoming', async (req, res) => {
  const sig = req.header('X-Signature');
  const ts = req.header('X-Timestamp');
  if (!sig || !ts || !verifyCloudSignature(sig, ts, req.body)) {
    return res.status(401).json({ ok: false, err: "invalid signature" });
  }
  const body = req.body;
  const channel = await client.channels.fetch(CONFIG.CHANNEL_ID);
  if (!channel) return res.status(500).json({ ok: false, err: "channel not found" });
  const embed = new EmbedBuilder()
    .setTitle(body.subject)
    .setDescription((body.details || "").slice(0, 1900))
    .addFields(
      { name: "Case ID", value: body.caseId || "unknown", inline: true },
      { name: "Reporter", value: body.anonymousPublic ? "Anonymous" : String(body.displayName || "Unknown"), inline: true },
      { name: "Timestamp", value: body.timestamp || new Date().toISOString(), inline: true }
    )
    .setColor(0xFFAA00);

  const confirmBtn = new ButtonBuilder().setCustomId("confirm::" + body.caseId).setLabel("Confirm bug").setStyle(ButtonStyle.Success);
  const declineBtn = new ButtonBuilder().setCustomId("decline::" + body.caseId).setLabel("Decline bug").setStyle(ButtonStyle.Danger);

  const row = new ActionRowBuilder().addComponents(confirmBtn, declineBtn);

  try {
    await channel.send({ embeds: [embed], components: [row] });
    return res.json({ ok: true });
  } catch (err) {
    console.error("Failed to send discord message", err);
    return res.status(500).json({ ok: false, err: "send failed" });
  }
});

app.listen(CONFIG.PORT, () => {
  console.log("Bot express listening on", CONFIG.PORT);
});
