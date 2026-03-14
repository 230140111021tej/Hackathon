# Motor Control IP (Hackathon MVP) — 3‑Phase PWM + Protection + FPGA Results

This repository contains an RTL **Motor Control IP** developed for the **Industrial & Automotive IP Development (Track B: Motor Control IP)** hackathon theme.

The IP provides a functional MVP featuring:
- **3‑phase PWM generation** (A/B/C phases)
- **Configurable duty cycle and frequency**
- **Deadtime insertion** for complementary high/low gate outputs
- **Basic protection** (overcurrent + emergency stop)
- **Modular architecture** (**Control Path** + **Data Path**)
- **Simulation testbench + waveform validation**
- **FPGA implementation results** (timing/power/resource)

---

## 1. MVP Requirements Checklist (Track B)

| Requirement | Implemented? | Notes |
|---|---:|---|
| 3‑phase PWM generation | ✅ | Complementary `high/low` outputs for phases A/B/C |
| Configurable duty cycle | ✅ | `duty_a_in`, `duty_b_in`, `duty_c_in` captured into internal registers |
| Configurable frequency | ✅ | `freq_in` → `freq_div` sets PWM counter maximum |
| Basic protection logic | ✅ | `overcurrent` / `emergency_stop` create `fault_detect`; PWM is gated off |

---

## 2. Repository Structure

- `Codes/`
  - `Motor_Control_Top.v` — top-level integration
  - `Control_Path/`
    - `Sync_Block` — 2‑FF synchronizer
    - `Protection_Unit` — fault detection
    - `Control_Fsm` — FSM generating `pwm_enable` and `fault_flag`
  - `Data_Path/`
    - `Register_Bank` — stores duty/frequency/deadtime
    - `Pwm_Engine` — counter + compare + deadtime
    - `Sub_Modules/` — `pwm_counter`, `compare_logic`, `deadtime_block`
- `Testbench` — simulation testbench (Icarus/Vivado compatible)
- `LICENSE` — MIT

---

## 3. Block-Level Architecture (Control Path vs Data Path)

### Data Path (signal flow)

Configuration inputs → **Register Bank** → (duty_a/b/c, freq_div, deadtime) → **PWM Engine** → **PWM Counter** → counter_value → **Compare Logic** → pwm_a/b/c_raw → **Deadtime Blocks** → PWM outputs

### Control Path (FSM flow)

System reset → input synchronization (start / emergency_stop / overcurrent) → **IDLE** (pwm_enable=0)
- If `start=1` → **RUN** (pwm_enable=1)
- If fault detected → **FAULT** (pwm_enable=0, fault_flag=1) → **RESET** → back to **IDLE**

### Cross-path signals

- **Control Path → Data Path:** `pwm_enable`
- **Control Path → Data Path (optional/config capture):** `control_in` (= synchronized start) into `register_bank`
- **Data Path → Control Path:** none in current MVP (no datapath feedback signal)

---

## 4. Top-Level Module

**Top module:** `motor_control_top`  
File: `Codes/Motor_Control_Top.v`

### Inputs
- `clk` : system clock
- `rst` : async reset
- `start` : start request (synchronized internally)
- `emergency_stop` : emergency stop input (synchronized internally)
- `overcurrent` : overcurrent input (synchronized internally)
- `write_enable` : captures configuration registers
- `duty_a_in`, `duty_b_in`, `duty_c_in` : duty settings
- `freq_in` : PWM counter maximum
- `deadtime_in` : deadtime (clock cycles)

### Outputs
- `fault_flag`
- `pwm_a_high`, `pwm_a_low`
- `pwm_b_high`, `pwm_b_low`
- `pwm_c_high`, `pwm_c_low`

### Key behavior
- Async inputs are synchronized using `sync_block`.
- `protection_unit` detects and latches faults.
- `control_fsm` controls run/fault state.
- Final PWM enable:
  - `pwm_enable = fsm_pwm_enable & ~fault_detect`

---

## 5. PWM Operation Details

### Raw PWM generation
- For each phase: `pwm_raw = (counter < duty)` (edge-aligned PWM)

### Counter / frequency
- Counter runs from 0 upward and resets when `count >= freq_div`.
- PWM period is approximately `(freq_div + 1)` clock cycles.

### Deadtime
- `deadtime` is specified in clock cycles.
- Deadtime block ensures a gap where both outputs are OFF during switching.

---

## 6. Verification

A simulation testbench is included in the file: `Testbench`.

What it tests:
- Reset
- Configuration load (`write_enable`)
- Start/run PWM
- Duty updates while running
- Frequency changes
- Overcurrent fault behavior
- Emergency stop behavior

Waveform evidence (VCD) is generated:
- `motor_control.vcd`

---

## 7. How to Run Simulation

### Icarus Verilog (example)

> Note: file extensions in this repo may be mixed (`.v` and no-extension). Update paths to match your local checkout.

```sh
iverilog -g2012 -o sim.out \
  Codes/Motor_Control_Top.v \
  Codes/Control_Path/Sync_Block \
  Codes/Control_Path/Protection_Unit \
  Codes/Control_Path/Control_Fsm \
  Codes/Data_Path/Register_Bank \
  Codes/Data_Path/Pwm_Engine \
  Codes/Data_Path/Sub_Modules/pwm_counter.v \
  Codes/Data_Path/Sub_Modules/compare_logic.v \
  Codes/Data_Path/Sub_Modules/deadtime_block.v \
  Testbench

vvp sim.out
# view waveform:
# gtkwave motor_control.vcd
```

### Vivado Simulation
- Add RTL + `Testbench`
- Run Behavioral Simulation
- Inspect waveforms for PWM/enable/fault/deadtime

---

## 8. FPGA Implementation Results (Vivado)

### Resource utilization (implementation)
- LUT: ~87
- FF: ~84
- BRAM: 0
- DSP: 0

### Timing summary (implemented)
- WNS (setup): +4.671 ns
- TNS: 0.000 ns
- Failing endpoints: 0
- WHS (hold): +0.183 ns
- WPWS (pulse width slack): +4.500 ns

### Power summary (implemented)
- Total on-chip power: 0.076 W
  - Static: 0.072 W (94%)
  - Dynamic: 0.004 W (6%)

---

## 9. Roadmap (Advanced Enhancements)

- Sensorless control strategy
- Torque estimation
- Closed-loop control (current + speed loops)
- Enhanced fault handling (sticky faults, fault codes, explicit clear)
- Standard configuration/register interface (AXI-lite/APB/Wishbone)

---

## License

MIT License — see `LICENSE`.