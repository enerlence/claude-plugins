# Production health and consumption analysis

How to request Suntropy's analysis of a plant, how to read it and how to find the cause of each finding. These are **model estimates**, not measurements.

## Requesting it

| User's question | Tool | Cost |
|---|---|---|
| "Is this plant OK?", "is it producing what it should?", "why did it drop?", "what is happening with its consumption?" | `get_production_health(plantId)` | Free if cached (one week). `refresh: true` recomputes it: 30-60 s and a few cents. Only when the user asks for today's figures or the analysis is several days old. |
| "Has *when* it consumes changed?", "is someone charging a car at night?" (brands with hourly consumption) | `get_consumption_daily_curve(plantId)` | Once a week, 14 hourly days from the manufacturer; cached afterwards. `unavailable` for Huawei, Solis and Fronius. |
| "What is causing the consumption change?" | `estimate_consumption_cause(plantId)`; if it returns `not_computed` and the user wants to know, `estimate: true` | Without `estimate`, free. With it: Huawei, 5 history calls (its tightest quota: other hourly reads may fail for a while); other brands, 3. Cached a week. **Do not repeat it.** |
| "Which are my important plants?" | `get_pinned_plants` | Free. |

A sensible order for "analyse this plant":
1. `get_production_health`.
2. If there is an anomaly or a consumption change, `estimate_consumption_cause` (first without `estimate`).
3. If the brand has hourly consumption, `get_consumption_daily_curve`.
4. Alarms (`list_alarms`) and, to confirm, the curve of one or two days (§ Finding the cause, step 5).

For several plants, start with `get_pinned_plants`. Do not loop `refresh`.

## Where each figure comes from

- **Real production:** the plant's daily energy from the manufacturer's portal (same as `get_plant_energy`, `pv_yield`, `day`), last two years.
- **Irradiation:** daily solar radiation from Open-Meteo at the plant's coordinates (satellite reanalysis, ~10 km cells: it misses very local clouds).
- **Expected:** TimesFM 3.0, Google's time-series model. It sees production up to 30 days ago and predicts those 30 days with each day's irradiation, **without seeing what the plant produced**. Median plus a p10-p90 band.
- **Health score (0-100), last 30 days:**
  - 70 %: real vs expected production for the sun there was (≥95 % = 100; ≤50 % = 0);
  - 30 %: yield per unit of irradiation vs the same weeks last year: catches slow losses;
  - caps: 40 at most if the plant is still stopped on the last day; 80 at most if 3 or more days of data are missing at the end.
  - Good ≥ 85 · Check 60-84 · Bad < 60.
- **Expected from last year:** each day's irradiation × what the plant yielded (kWh per MJ/m²) on the same dates last year (±10 days). Model-free reference. If TimesFM says fine but this is low, the loss is slow (soiling, new shade, a string) and the model has absorbed it.
- **Consumption (plants with a meter only):** TimesFM with two years of daily consumption plus temperature and weekend as covariates. It follows cold and heat but not one-off peaks, so the daily forecast is almost flat with a wide band: judge the **total**. Estimated self-consumption = f × min(expected production, expected consumption) per day, f being what was really self-consumed of that minimum in the reference period (captures timing and battery).
- **Findings:**
  - `stop`: consecutive days with near-zero production when production was expected;
  - `drop`: below the band and below half the expected, without reaching zero;
  - `no_data`: days without manufacturer data. **No data is not no production**: the plant may have produced and not reported it;
  - `degradation`: when working, it yields 10 % or more below last year with the same sun.

## Evaluating the results

1. **Can I trust the data?**
   - `dataRange.daysWithData` vs `requestedDays`, and `fullYear`. Without a year, the historical 30 % and last year's reference do not exist.
   - `health.insufficientHistory`: under 60 days there is no score. Say so; do not invent.
   - `health.confidence`: low with little data.
   - `meta.generatedAt`: if the analysis is 3-4 days old and the question is about "now", say so or use `refresh`.
2. **Production:**
   - `health.score`, after checking `health.caps` (`ongoing_stop`, `missing_recent_data`): a low score may come from a cap, not from yield.
   - `health.recent.ratio` (real/expected over 30 days) vs `health.historical.ratio` (yield per sun vs last year):
     - `recent` low, `historical` normal → something recent: stop, drop, limitation;
     - `recent` normal, `historical` low → **slow loss** (soiling, new shade, a string) the model has absorbed; `lastYear.ratio` confirms it without the model;
     - both low → a lasting problem.
   - `days`: the p10-p90 band holds ~80 % of a healthy plant's days. One day outside is usually a local cloud (check `irradiationMJ` against its neighbours); **two or more consecutive** days with `anomaly: true` are a real episode.
   - `findings`: each with days and lost kWh. Diagnose with § Finding the cause.
3. **Consumption** (`consumption`; `null` without a meter):
   - `balance.real` vs `balance.expected` per series: ±10 % normal, ±25 % to check, beyond that an anomaly. Start with consumption: if it soars, grid import rises with it.
   - `change` (last year vs the previous one at equal temperature): `status: change` with `perDayKwh`, `onset` and `hypothesis` (`ev_or_new_load`, `new_constant_load`, `electric_heating`, `air_conditioning`, and their `less_*` opposites); `seasonal` lists changes with cold or heat. With `fit` < 0.15 consumption is very irregular: present it with caution.
   - **Not contradictory:** an anomaly in the window (+70 %) and `change.status: no_change` for the year. The anomaly is recent and does not weigh on the year yet. Say "these weeks yes; over the year, not yet".
   - `weekly`: `more_weekend` / `less_weekend` / `day_changed` (12-week medians). Home: more time at home, remote work, a fixed-day load. Business: now opens or closes at weekends.
4. **Daily curve** (`get_consumption_daily_curve`), shape only, against the same week last year:
   - `night_load` / `evening_load` with hours and kW: the typical footprint of an EV, a water heater or storage heaters;
   - `base_load_up` / `down`: an always-on device appeared or left (pool pump, dehumidifier, server, old fridge);
   - `more_at_solar_hours` / `less_at_solar_hours`: if less, suggest moving washing machine, dishwasher, water heater or car charging to midday.
5. **Estimated cause** (`estimate_consumption_cause`):
   - Each cause has `confidence` and `evidence`. **Quote the evidence** with its figures: "a stable 7.2 kW block from 1:10 to 3:00, the power of a 7.4 kW charger, absent on 8 Oct", or "a 1.3 kW load switching 38 times in 18 h, like a thermostat, with base load from 0.22 to 0.93 kW".
   - With `low` confidence, present it as one possibility among others. If `reference` is `null` or `partial: true`, the before/after comparison is missing: say so.
   - Always present it as an estimate: we do not see the appliances; confirm with the customer.

## Finding the cause

Cheap to expensive, all requests for a plant together, no repeated calls. Stop when a cause is backed by data.

1. **Alarms of the period:** `list_alarms` with `plantIds: [plantId]`, `state: "all"` and `from` two days before the finding starts. Closed ones count: a grid, insulation or string alarm opened the day the finding starts is usually the cause.
2. **Status now:** `get_plant_status` and, to go down to the equipment, `list_devices` + `get_device_realtime` for all its inverters in one call.
3. **By finding type:**

| Finding | What to check | How to read it |
|---|---|---|
| `stop` | Alarms since the start · `get_device_realtime` of the inverter · `get_plant_energy` `hour` of one stopped day (1-2 days only) | Grid alarm (`Grid Loss`, `Grid Failed`, overvoltage) → grid outage, tripped breaker or RCD, or the DSO. Inverter shut down without alarm → switched off or a protection tripped. Inverter running at 0 kW in daylight → DC side (isolator, fuses, connectors). Zeros together with `Network Connection Error` may be communications, not a stop: say so. |
| `drop` | `get_plant_energy` `hour` of the drop day vs a similar normal day · alarms · per-string/MPPT power in `get_device_realtime` or `get_device_history` | Flat clipped curve at midday → export or power limitation. Normal curve until a time and then zero → trip or disconnection that day. One MPPT/string at 0 A in sunshine → string down. Very cloudy day with the customer's nearby plants also down → weather. |
| `no_data` | Communication alarms (`Network Connection Error`, dongle, datalogger) · `get_plant_status` (`stale`, `dataAt`) | Datalogger or internet: router, wifi, power cuts in the house, the dongle. Whether it produced cannot be known. The energy often reappears in the portal once the connection returns, if the inverter stored it. |
| `degradation` | `specific_yield` by month this year and last · nearby plants of the same customer · `get_device_realtime` of all inverters | Slow loss without alarms while neighbours are fine → soiling, new shade (tree, building work) or a degraded panel/string. One inverter far below its twin → that inverter or its strings. |

4. **Consumption and self-consumption:** consumption far above expected and reference → new habits or equipment (heat pump, EV, pool); below → holidays or an empty house. Not a plant fault: say so. Real self-consumption well below the estimate with normal consumption → consumption moved to the night, or the battery does not charge/discharge (check the battery's `get_device_realtime`: SOC, power), or export limitation or the meter are misconfigured.
5. **Confirm with one day's curve:** `get_plant_power_curve` (consumption) for 2-3 recent days and one similar day before the onset, no more. Huawei has no plant curve: use `get_device_history` for one day of the power meter and the inverter (consumption = inverter + grid import − grid export; check the sign at night, when everything the meter reads is consumption). EV = flat block of 3.7, 7.4 or 11 kW for hours, usually at night or on arrival home; heat pump = 1-3 kW cycles in cold hours; air conditioning = summer afternoons; pool = 0.7-1.5 kW daytime block in summer.
6. If the data is not enough, say so and say what you would check on site.

## How to answer

- Per finding: **what happened** (date and figure), **the most likely cause and the data that shows it**, **how much energy was lost**, **whether it is urgent** and **what to do**, saying whether a site visit is needed.
- If the cause is not certain: "most likely…, because…; to confirm it, …".
- For a consumption change: what changed and since when, what it costs per year (kWh/day × 365 × tariff price if known, else kWh), how much the panels could cover, and the opportunity (shift the load to solar hours, battery, extension). It is a useful sales conversation for the installer: say it tactfully.
