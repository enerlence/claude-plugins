# Suntropy Connect Monitoring for Claude

Plugin from [Suntropy](https://suntropy.ai) that lets Claude read your solar PV plants from the inverter-monitoring platforms you already use, all at once: Huawei FusionSolar, Sungrow iSolarCloud, GoodWe SEMS, Deye Cloud, SolisCloud, Enphase Enlighten, Growatt, Fronius Solar.web, SolarEdge, Riello and GreenHeiss.

## What it includes

- **MCP connector**: the remote Suntropy Connect server at `https://connect-gateway.suntropy.ai/monitoring/mcp`. Sign-in uses OAuth 2.1 with PKCE: the first time, Claude opens the Suntropy sign-in page (you can create an account there with a 6-digit email code). No API keys or manufacturer passwords are stored in the plugin.
- **Skill `suntropy-connect-monitoring`**: how to answer about plants, production, self-consumption and alarms while saving the manufacturers' API quota (many plants in one call, no repeated questions, `null` is not zero). With three annexes Claude opens only when needed:
  - `diagnosis.md`: step-by-step diagnosis of a plant that produces little, and real production vs the design;
  - `production-health.md`: reading Suntropy's production-health analysis (TimesFM forecast, findings, consumption changes and their estimated cause);
  - `alarm-triage.md`: classifying alarms by urgency, communication losses, recurring alarms and silences.

## Install

From the Claude directory, or in Claude Code:

```
/plugin marketplace add enerlence/claude-plugins
/plugin install suntropy-connect-monitoring@suntropy
```

## What you can ask

- "How are my plants doing today? Which ones are offline or have alarms?"
- "The Pérez plant produced almost nothing yesterday. Find out why."
- "Compare this month's production of my three biggest plants with last month."
- "Show me the critical alarms from the last week and mark the ones that already cleared as read."
- "Connect my Huawei FusionSolar account."

## Data and network

The plugin sends requests only to `connect-gateway.suntropy.ai`, operated by Suntropy (Enerlence Software Solutions S.L.). Suntropy reads the manufacturers' platforms with the accounts you connect and never writes to your plants or inverters. It contains no hooks, scripts or local code. Data is processed under the [Suntropy privacy policy](https://suntropy.ai/politica-privacidad/).

## Requirements

A Suntropy account (free to create) with at least one inverter-monitoring account connected, in Suntropy (Settings > Suntropy Connect > Connectors) or from Claude itself with "connect my … account". Using it from Claude includes a 7-day free trial of Suntropy Connect; see [connect.suntropy.ai](https://connect.suntropy.ai) for pricing.

## Documentation

- [Suntropy Connect for AI agents](https://www.suntropy.ai/connect/agentes/)
- [connect.suntropy.ai](https://connect.suntropy.ai)

## Support

hola@suntropy.ai

## License

MIT, see `LICENSE`.
