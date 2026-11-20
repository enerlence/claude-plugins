# Alarm triage

How to review a batch of alarms and tell the user what matters. For listing alarms, `SKILL.md` § Alarms is enough.

## Investigate, cheap to expensive

1. `get_plant_status` for **all** the plants with alarms at once: are they producing? what energy today?
2. `list_alarms` with their `plantIds` (open ones): is the alarm still open? others on the same plant? since when (`raisedAt`)? An alarm that is no longer open resolved itself: say so.
3. If an alarm belongs to a device, `get_device_realtime` with all those `deviceId`s at once: state, power, voltages.
4. Only if the plant produces but you suspect a loss: `get_plant_energy` `pv_yield` by `hour`, today vs yesterday.

**Mind the plant's local time:** at night, an inverter "disconnected" or "without grid" is normal for many brands; say so and lower the urgency.

## Classify each plant

Group a plant's alarms into one problem ("no grid" + datalogger "no communication" = one problem), then:
- **Act now:** the plant or an inverter does not produce in sunshine, insulation or earth fault, a critical alarm still open, battery fault.
- **Check soon:** it produces but less (a string down, a low MPPT), an intermittent major alarm, communication lost for hours.
- **No action:** already closed, night-time disconnection, informational notice.

Answer with one line per plant, most urgent first: plant, classification, what is happening and since when, whether it produces, and what to do. Plants with no action, together in a final line.

## Communication losses

About half of all alarms ("Network Connection Error", "Connection failure between Inverter and Solar.web", "Communication failure between Datamanager…", "Faulty Power Collector"). They mean **the manufacturer's portal is not receiving data**, not that the plant is not producing, and most recover by themselves.
- Still open? If closed: "No action, recovered by itself after X h".
- At night, or started at sunset and closed at dawn? Many dataloggers switch off with the inverter: "No action".
- Does it produce? If the plant or inverter shows power or energy today, it is only communications: "Check soon" at most ("the plant produces; only the link to the portal is lost").
- "Check soon" when it has not recovered after 24 h or has dropped 3 or more times in 3 days. The fix is usually the router, the wifi or 4G coverage of the datalogger, or restarting it; say it in plain words.
- "Act now" only if the plant also does not produce in sunshine.
- With alarm watching on, `get_alarm_watch` shows `waitingToRecover` (communication losses Suntropy is holding a few hours before reviewing, with `releaseAt`) and `recoveredByThemselves` (the ones that came back on their own and how long they lasted).

## Suntropy production-analysis alarms

Some alarms do not come from the manufacturer but from Suntropy's monthly production analysis. Their code starts with `ANALYSIS_` (`ANALYSIS_STOP`, `ANALYSIS_DROP`, `ANALYSIS_UNDERPERFORMANCE`, `ANALYSIS_DEGRADATION`, `ANALYSIS_NO_DATA`, `ANALYSIS_ANTI_EXPORT`, `ANALYSIS_CONSUMPTION_CHANGE`).
- They look at the **last 30 closed days**, not at now. Check with `get_plant_status` whether the plant produces today and with `list_alarms` whether the manufacturer had alarms on the same dates. Do not look the code up in manufacturer documentation: it does not exist there.
- A stop that continues: act now if it still does not produce in sunshine; if it produces today, say so and lower it to check soon.
- Underperformance and degradation: check soon; give the lost kWh, look at daily `pv_yield` and the string readings ([production-health.md](./production-health.md)).
- Anti-export (production limited to consumption): **not a fault**, it is the configuration. Present it as an opportunity (a battery would use those kWh).
- No-data days: a past communication loss, usually no action if there is data today.
- Consumption change: not a fault; an opportunity (extension, battery), and the cause is always an **estimate**.

## Recurring alarms and silences

Many inverters close an alarm and reopen it shortly after (grid overvoltage at midday, a communication loss). Suntropy groups them by **plant + device + code**.
- Going and coming usually points to the grid or something intermittent; getting worse (more frequent, more severe) is a reason for "check soon" or "act now". Say how many times it fired and since when.
- `silence_alarm_reviews` pauses Suntropy's automatic AI reviews of that alarm (or of the whole plant without `alarmId`) for some hours; the alarms are still read, stored and listed. Suggest it, and use it only if the user agrees, when after investigating the alarm needs no attention and will keep repeating: short (6-72 h), with a one-sentence `reason`. Prefer silencing the alarm over the whole plant.
- Never silence when the plant or an inverter does not produce in sunshine, there is an insulation, earth or battery fault, or it is getting worse.
- Active silences are in `get_alarm_watch`; `lift_alarm_silence` removes one.
