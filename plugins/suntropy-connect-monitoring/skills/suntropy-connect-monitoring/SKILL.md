---
name: suntropy-connect-monitoring
description: Use when the user asks how their solar PV plants are doing, how much a plant produced, consumed, self-consumed or exported, why a plant produces little or stopped, what an inverter alarm means, whether a plant produces what it was designed for, or wants to connect a Huawei FusionSolar, Sungrow iSolarCloud, GoodWe SEMS, Deye Cloud, SolisCloud, Enphase Enlighten, Growatt, Fronius Solar.web, SolarEdge, Riello or GreenHeiss account, and the Suntropy Connect monitoring tools are available (get_monitoring_summary, list_plants, get_plant_status, list_alarms…).
---

# Suntropy Connect Monitoring

The `suntropy-connect-monitoring` MCP server reads the user's PV plants live from the manufacturers' monitoring platforms, all connected brands at once. **Answer about a plant from the tools, never from memory or documentation.** Nothing is ever written to the plants or inverters. Power is in kW and energy in kWh, whatever the brand.

## The tools

| Tool | What for |
|---|---|
| `get_monitoring_summary` | **Everything in one call**: per account, how many plants, healthy / faulty / offline, kWp, energy today and this month, and the failing plants by name and id. Start here for any overview. |
| `list_connections` | Connected accounts, their status and error. Use it when a brand brings no plants. Carries `manageUrl` and sometimes `missingPlantsHint`. |
| `list_plants` | Plants (name, address, kWp, commissioning), **25 per page** (`total`, `nextOffset`). Search with `query` (name or address) instead of paging. Its ids (`huawei:3f2a9c1e:NE=…`) are the ones the other tools take. Each plant has `openUrl`. |
| `get_plant_status` | Health and energy today / this month / total for specific plants, up to 100 in one call. With ≤10 plants and brands that report it, `flow` (PV, load, grid and battery now). Unknown ids come back in `unknownPlantIds`. |
| `get_plant_energy` | **One** metric per call as a `[period, value]` series plus total: `pv_yield`, `consumption`, `grid_export`, `grid_import`, `self_consumption`, `battery_charge`, `battery_discharge`, `inverter_yield`, `irradiation`, `performance_ratio`, `specific_yield`, `income`. Granularity `5min` / `hour` / `day` / `month` / `year`, at most 744 points. |
| `get_plant_power_curve` | 5-minute power of one day (kW): PV, load, grid (+ export) and battery (+ discharge). Not available for Huawei. |
| `list_devices` | Inverters, batteries, meters… of a plant. |
| `get_device_realtime` | Latest reading of one or many devices (string voltages and currents in `measurements`). |
| `get_device_history` | 5-minute readings of ONE device, 24 h at most. The most rationed call: only the days you need. |
| `get_device_settings` | Battery, work mode and charge schedule settings, read only. |
| `list_alarms` | Alarms, most severe first, with the manufacturer's cause and suggestion. Filters: `plantIds`, `minSeverity`, `unreadOnly`, dates, `state`. |
| `get_quota_status` | **Why data is not coming when a manufacturer throttles**: per account, whose quota it is (`scope`: the installer's account, their key, or Suntropy's shared app, `shared`), usage today / this month, paused until when (`pause.until`, UTC). Costs no manufacturer calls. |
| `get_alarm_watch` | Which brands have alarm watching on, active silences, and communication losses waiting to recover. |
| `set_alarm_watch` ✎ | Turns alarm watching on or off. **Turning it off deletes the stored alarms of that brand**: confirm with the user first. |
| `poll_alarms` ✎ | Reads one brand's alarms now (only with watching on). |
| `mark_alarms_read` ✎ | Marks alarms read **for the whole company**, not just this user. Only when asked. |
| `silence_alarm_reviews` · `lift_alarm_silence` ✎ | Pause or resume Suntropy's automatic AI reviews of a recurring alarm. The alarms are still stored and listed. |
| `get_production_health` | **Suntropy's analysis of a plant**: production health 0-100 against a TimesFM forecast, findings, day by day real vs expected and, with a meter, consumption. Cached a week; `refresh` recomputes it (30-60 s). How to read it: [production-health.md](./production-health.md). |
| `get_consumption_daily_curve` | Changes in the **shape** of the daily consumption curve (new night or evening load, base load, solar hours). Not for Huawei, Solis or Fronius. |
| `estimate_consumption_cause` | **Estimated cause** of a consumption change (EV charging, electric heating, air conditioning, always-on load) with confidence and evidence. |
| `get_pinned_plants` · `set_pinned_plants` ✎ | The plants the user pinned as priorities in Suntropy. Change them only when asked. |
| `get_connection_catalog` · `create_connection_link` ✎ | Connect a new manufacturer account (see § Connecting an account). |

## Rules that save quota (and time)

The manufacturers ration their APIs per account; running out also blocks the installer's own portal.

1. **Everything you can in one call.** For an overview, `get_monitoring_summary`, never `list_plants` + `get_plant_status` of every plant. For several specific plants or devices, all of them at once in `get_plant_status` / `get_device_realtime`. Never plant by plant.
2. **Do not repeat a question.** Answers carry `freshness.ageSeconds`; asking again before it expires returns the same data.
3. **A quota error says when to retry**: tell the user and do not loop. To explain it, `get_quota_status` of that account: which query is exhausted, whose quota it is and until when (convert to the user's local time). Cached data and other queries (hourly, real-time, alarms) may still work: offer them. If the quota belongs to Suntropy's shared app (`shared`), say so: it is not the user's account.
4. **`issues` is not "no plants".** When one account fails the others still answer and the failure is in `issues`: report it and point to `list_connections` / `manageUrl`.
5. **`null` is not zero.** A value the plant does not measure (no meter, no battery) is `null`. Never say "produced 0 kWh" from a `null`.
6. **Plant local time**, and **today is still growing**: do not compare today with a closed day as if it were complete.

## Flows

Pick the one that fits and start calling tools without preamble. Open an annex only for its task:

| File | Open it when… |
|---|---|
| [diagnosis.md](./diagnosis.md) | you are going to diagnose a plant that produces little, or compare real production with the design. |
| [production-health.md](./production-health.md) | the user asks to **analyse a plant** (is it producing what it should? what happened to its consumption?) or about the health score, findings or consumption change, and you will call `get_production_health`, `get_consumption_daily_curve` or `estimate_consumption_cause`. |
| [alarm-triage.md](./alarm-triage.md) | the user asks to review, prioritise or explain a batch of alarms, or about repeated alarms, communication losses or silences. |

### "How are my plants?"
1. `get_monitoring_summary`. One call; nothing else is needed.
2. Answer with the faulty and offline plants first (from `problems`, by name; with `moreProblems`, say how many more), then today's and this month's total and how many are fine ("the other 74, fine"). With several accounts, one line per source. If an account is in error or in `issues`, say so.
3. Offer to look at the alarms of the failing ones (`list_alarms` with their `plantIds`, already in `problems`).

### "How much did X produce in …?"
1. `list_plants` with `query` if you do not have the id.
2. `get_plant_energy` with `pv_yield` and the granularity the period calls for (a day → `hour`, a month → `day`, a year → `month`, several years → `year`). Give the total and, if useful, the best and worst period.
3. To compare plants of different size use `specific_yield` (kWh/kWp), not kWh.

### Self-consumption, export and battery
One call per metric (`self_consumption`, `grid_export`, `grid_import`, `battery_charge`…). Self-consumption rate = `self_consumption / pv_yield`. If a metric is `null`, that plant does not measure it (no meter or battery): say so.

### Alarms
1. `list_alarms` (open ones by default). For what is urgent, `minSeverity: "major"`. For what is new, `unreadOnly: true`.
2. Group by plant, most severe first, with the manufacturer's cause and suggestion in one sentence.
3. If `sources` says a brand is read live (no watching), warn that there is no history and offer to turn watching on (`set_alarm_watch`, **after confirming**).
4. To dig into an alarm: its `deviceId` → `get_device_realtime`.
5. **Check since when.** `raisedAt` is the start: an open alarm can be months old. Say it with the date ("stopped by NO-Grid since 1 June 2025"), not as if it were today's.
6. If `get_plant_status` or `get_device_realtime` show the inverter in alarm (`state: "alarm"`) and `list_alarms` has none for that plant, say exactly that ("the inverter reports an alarm but the platform does not detail it") instead of guessing the cause.

### "Since when has it not produced?"
Do not stop at the last month: if the whole range is 0, widen until you find the last day with production.
1. If there is an open alarm on the plant, its `raisedAt` is usually the stop date.
2. `get_plant_energy` with `pv_yield`, `granularity: "year"` (no range: all years) → last year with energy; then `"month"` of that year → last month; then `"day"` of that month → last day.
3. Answer with the date ("last production on 31 May 2025; 0 kWh since"), not "at least N days".

### Opening the plant in the manufacturer's portal
- Give the plant's **`openUrl`** as is (in `list_plants`, `get_plant_status` and the problem plants of `get_monitoring_summary`). The user signs in with their own portal account.
- If `openUrl` is `null` (always for FusionSolar; some regions of other brands), **do not build one**: say that platform has no direct link, give its home page (FusionSolar: `https://<config.host>/` of the account in `list_connections`) and the exact plant name to search for.
- The plant also has a page in Suntropy: `https://app.suntropy.ai/monitoring/plant?id=<plantId, URL-encoded>`.

### A plant that produces little
Open [diagnosis.md](./diagnosis.md) § Diagnosis.

### "Does it produce what we promised?" (real vs design)
Open [diagnosis.md](./diagnosis.md) § Real vs design.

## Connecting an account

If the summary or `list_connections` do not show the brand the user expects, it has to be connected.
- **Use `create_connection_link`**: a one-time link (15 minutes) that opens Suntropy's Connectors screen with the user's session, where they enter the credentials, so they never go through the chat. Sungrow and Enphase return `authorizeUrl` to authorise on the manufacturer's site. Afterwards, check `list_connections`.
- `get_connection_catalog` explains what each brand needs (an API account in FusionSolar, a token in Growatt, the paid Solar.web Query API in Fronius, OAuth in Sungrow…).
- **Never ask for credentials in the chat** (manufacturer passwords, API keys, tokens, or the Suntropy password). If the user pastes one, do not use or repeat it: give them the link instead.
- In FusionSolar the plant owner may have to accept "API access" in their app; plants can take a few hours to appear.
- Accounts can only be removed by the user, in Suntropy (Settings › Suntropy Connect › Connectors).

## How to answer

- **The figure first**, then the context, without narrating which tool you used.
- Units: kW for power, kWh/MWh for energy, % with one decimal. Round sensibly (1,234 kWh, not 1234.5678).
- If something cannot be known (brand without that measurement, quota exhausted), say it in one line and go on with what there is.
- Say "solar panels" (in Spanish, «paneles», never «placas»). Answer in the user's language.
