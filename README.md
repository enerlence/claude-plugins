# Suntropy plugins for Claude

Claude plugins from [Suntropy](https://suntropy.ai), the AI software for solar installers.

| Plugin | What it does |
|---|---|
| [`suntropy-connect-monitoring`](plugins/suntropy-connect-monitoring) | Read your PV plants from every connected inverter-monitoring platform: status, energy, devices, alarms and production health. |

## Install in Claude Code

```
/plugin marketplace add enerlence/claude-plugins
/plugin install suntropy-connect-monitoring@suntropy
```

## Other clients

The same remote MCP server (`https://connect-gateway.suntropy.ai/monitoring/mcp`, OAuth sign-in) works in other assistants:

- **Claude**: [connector directory](https://claude.ai/directory/connectors/suntropy-connect-monitoring) → Connect
- **Gemini CLI**: `gemini extensions install https://github.com/enerlence/claude-plugins`
- **Cursor**: plugin manifest in [`.cursor-plugin/plugin.json`](.cursor-plugin/plugin.json)
- **Codex**: `codex mcp add suntropy-connect --url https://connect-gateway.suntropy.ai/monitoring/mcp`
- **MCP Registry**: `ai.suntropy/connect` ([`server.json`](server.json))

## Support

hola@suntropy.ai

## License

MIT
