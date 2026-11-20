# Diagnosis and real vs design

The two long monitoring analyses, step by step. For status, production or alarms, `SKILL.md` is enough.

## Diagnosis: "plant X produces little"

Go from cheap to expensive and stop as soon as you find the cause. Ask for everything about the plant together, never device by device.

1. **Status and alarms.** `get_plant_status` for the plant and `list_alarms` with its `plantIds`. A tripped inverter or an insulation, grid or string alarm already explains it. Check `raisedAt`: an old alarm means the plant has been down since then (`SKILL.md` § "Since when has it not produced?").
2. **Little compared with what?** `specific_yield` by month (`get_plant_energy`, `granularity: "month"`) for this year and last year.
   - If the same customer has nearby plants (`list_plants` with `query` by town), get their `specific_yield` for the same period and compare. A plant 15-20 % below its neighbours under the same weather has its own problem; if all of them drop, it is the weather.
   - Where `irradiation` or `performance_ratio` are available (some brands), PR separates weather from faults: stable PR with low production = little sun.
3. **By day.** For the suspicious month, `pv_yield` with `granularity: "day"`: a step (half the production from one day to the next) points to an inverter or string down since that date; a gradual decline, to soiling or growing shade.
4. **By device.** `list_devices` and `get_device_realtime` for all inverters at once: compare the DC power of identical inverters and the string voltages/currents in `measurements`. A string at 0 A in sunshine, or an inverter far below its twin, is the fault.
5. **One day's curve.** If needed, `get_plant_power_curve` (or `get_device_history` of an inverter, for Huawei) on a clear day: flat clipping at midday = export limitation or inverter clipping; gaps = disconnections; an asymmetric curve = shade.

`get_production_health` gives a modelled view of the same question (health score, stops, drops, slow degradation): see [production-health.md](./production-health.md).

Close with: probable cause, the data that shows it (date, device, figure) and what to check on site. If there is no clear cause, say so and propose what to measure.

## Real vs design

What the plant produces against what was promised.

### 1. The real production

`get_plant_energy` with `pv_yield`, `granularity: "month"`, from commissioning or the last 12 complete months. Note the plant's `capacityKwp` too (`list_plants`).

### 2. The design

Use the design the user has:
- **A monthly production estimate** the user gives you (a Suntropy study, a PVGIS run, an offer, a PDF): take its 12 monthly values and its kWp.
- **PVsyst or PV\*SOL**: if their Suntropy Connect tools are available, read the monthly results of the simulated project or variant.
- If there is no design at hand, ask for it rather than estimating one.

If several candidate designs exist, ask which one, and confirm by comparing the design kWp with the plant's `capacityKwp`.

### 3. Compare

- **Month by month, complete months only:** real / design in %. Give the annual total and the months with the largest deviation.
- **The design is a simulated typical year**; the real one is not: ±10 % in one month is normal. What matters is the trend: every month below, or a drop from a given date (then continue with § Diagnosis).
- **If the kWp do not match** (the final installation changed), compare kWh/kWp: real `specific_yield` against the design production divided by its kWp.
- If the plant measures consumption, compare it too: a worse self-consumption than promised usually comes from a different consumption than estimated, not from the plant.

Close with a short table (month · design · real · %), stating where the design comes from, and a one-sentence conclusion.
