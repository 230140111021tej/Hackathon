# Motor Control IP (Hackathon MVP) — 3‑Phase PWM + Protection + FPGA Proof

**Hackathon Theme:** Industrial & Automotive IP Development  
**Track:** **B — Motor Control IP**  
**Repo:** `230140111021tej/Hackathon`

This repository contains an RTL **Motor Control IP** implementing a functional MVP for industrial/EV-style motor-drive subsystems. The core delivers **3‑phase PWM generation** with **configurable duty/frequency**, **deadtime insertion**, and **basic protection** (overcurrent + emergency stop), along with **simulation verification** and **FPGA implementation proof**.

---

## Quick Links (Proof & Diagrams)
- **Data Path vs Control Path:** `Images/data_path_vs_control_path.jpeg`
- **Data Path diagram:** `Images/data_path.jpeg`
- **Control Path diagram:** `Images/control_path.jpeg`
- **Vivado design run status:** `Images/design_runs.png`
- **Timing report screenshot:** `Images/Timing_report.png`
- **Power report screenshot:** `Images/Power_report.png`

> Tip: If you open this repo in GitHub, check the `Images/` folder to see the screenshots used for submission evidence.

---

## MVP Requirements Checklist (Track B)

| Requirement | Implemented? | Notes |
|---|---:|---|
| 3‑phase PWM generation | ✅ | Complementary `high/low` outputs for phases A/B/C |
| Configurable duty cycle | ✅ | `duty_a_in`, `duty_b_in`, `duty_c_in` captured into registers |
| Configurable frequency | ✅ | `freq_in` → `freq_div` controls PWM counter maximum |
| Basic protection logic | ✅ | `overcurrent` / `emergency_stop` create `fault_detect`; PWM gated off |

---

## Repository Structure

```
.
├─ Codes/
│  ├─ Motor_Control_Top.v
│  ├─ Control_Path/
│  │  ├─ Control_Fsm
│  │  ├─ Protection_Unit
│  │  └─ Sync_Block
│  └─ Data_Path/
│     ├─ Register_Bank
│     ├─ Pwm_Engine
│     └─ Sub_Modules/
│        ├─ Compare_Logic
│        ├─ Deadtime_Block
│        └─ Pwm_Counter
├─ Images/
│  ├─ design_runs.png
│  ├─ Timing_report.png
│  ├─ Power_report.png
│  ├─ data_path_vs_control_path.jpeg
│  ├─ data_path.jpeg
│  └─ control_path.jpeg
├─ Testbench
├─ README.md
└─ LICENSE
```

> Note: Some RTL files in this repo intentionally have **no `.v` extension** (e.g., `Control_Fsm`). They are still Verilog modules and can be compiled by explicitly listing the file paths.

---

## Top-Level Module

**Top module:** `motor_control_top`  
**File:** `Codes/Motor_Control_Top.v`  
**Parameter:** `WIDTH` (default: 12)

### Inputs
- `clk` : system clock  
- `rst` : async reset  
- `start` : start request (synchronized internally)  
- `emergency_stop` : emergency stop (synchronized internally)  
- `overcurrent` : overcurrent fault (synchronized internally)  
- `write_enable` : captures configuration registers  
- `duty_a_in`, `duty_b_in`, `duty_c_in` : duty settings (`WIDTH` bits)  
- `freq_in` : PWM counter maximum (`WIDTH` bits)  
- `deadtime_in` : deadtime in clock cycles (`WIDTH` bits)

### Outputs
- `fault_flag`
- `pwm_a_high`, `pwm_a_low`
- `pwm_b_high`, `pwm_b_low`
- `pwm_c_high`, `pwm_c_low`

---

## Architecture (Control Path + Data Path)

### Control Path (`Codes/Control_Path/`)
- **`Sync_Block`**: 2‑FF synchronizer for async inputs
- **`Protection_Unit`**: detects faults from `overcurrent` or `emergency_stop`
- **`Control_Fsm`**: FSM generating `pwm_enable` and `fault_flag`

### Data Path (`Codes/Data_Path/`)
- **`Register_Bank`**: stores `duty_a/b/c`, `freq_div`, `deadtime`, `control_reg` on `write_enable`
- **`Pwm_Engine`**:
  - `Sub_Modules/Pwm_Counter` → counter generation up to `freq_div`
  - `Sub_Modules/Compare_Logic` → raw PWM: `(counter < duty_x)`
  - `Sub_Modules/Deadtime_Block` → complementary outputs with deadtime

### Cross-path signals
- **Control → Data:** `pwm_enable`
- **Control → Data (config capture in this MVP):** `control_in` (= synchronized `start`) into `Register_Bank`
- **Data → Control:** none in current MVP

---

## PWM Operation Details

### Raw PWM generation
For each phase:
- `pwm_raw = (counter < duty)` (**edge-aligned PWM**)

### Frequency control
- `pwm_counter` counts from 0 upward and resets when `count >= freq_div`
- PWM period ≈ **(freq_div + 1)** clock cycles

### Deadtime
- `deadtime_in` is specified in **clock cycles**
- `Deadtime_Block` enforces a switching gap where both complementary outputs are OFF

---

## Verification (Simulation)

A simulation testbench is included in the file: `Testbench`.

### What the testbench exercises
- Reset behavior
- Register/config load via `write_enable`
- Start/run PWM
- Duty updates during run
- Frequency changes (including extreme change)
- Fault behavior:
  - Overcurrent fault test
  - Emergency stop test
- Restart after fault stimulus
- Corner cases:
  - duty = 0
  - duty = max (`4095` for WIDTH=12)
  - larger deadtime

### Waveform output
- VCD dump file: **`motor_control.vcd`**

---

## How to Run Simulation

### Icarus Verilog (example)
```sh
iverilog -g2012 -o sim.out \
  Codes/Motor_Control_Top.v \
  Codes/Control_Path/Sync_Block \
  Codes/Control_Path/Protection_Unit \
  Codes/Control_Path/Control_Fsm \
  Codes/Data_Path/Register_Bank \
  Codes/Data_Path/Pwm_Engine \
  Codes/Data_Path/Sub_Modules/Pwm_Counter \
  Codes/Data_Path/Sub_Modules/Compare_Logic \
  Codes/Data_Path/Sub_Modules/Deadtime_Block \
  Testbench

vvp sim.out
# view waveform:
# gtkwave motor_control.vcd
```

### Vivado Simulation
- Add all RTL files + `Testbench`
- Run Behavioral Simulation
- Inspect waveforms for: PWM outputs, `pwm_enable`, `fault_flag`, `fault_detect`, deadtime behavior

---

## FPGA Implementation Results (Vivado) — Evidence in `Images/`

### Resource utilization (implementation)
- **LUT:** ~87  
- **FF:** ~84  
- **BRAM:** 0  
- **DSP:** 0  

### Timing summary (implemented)
- **WNS (setup):** +4.671 ns  
- **TNS:** 0.000 ns  
- **Failing endpoints:** 0  
- **WHS (hold):** +0.183 ns  
- **WPWS (pulse width slack):** +4.500 ns  

### Power summary (implemented)
- **Total on-chip power:** 0.076 W  
  - Static: 0.072 W (94%)  
  - Dynamic: 0.004 W (6%)

---

## Roadmap (Advanced Enhancements)
Planned upgrades beyond MVP:
- Sensorless control strategy (observer/PLL/SMO)
- Torque estimation algorithm
- Closed-loop architecture (current loop + speed loop)
- Enhanced fault handling:
  - sticky faults, fault codes, explicit fault clear
- Standard config/register interface for integration:
  - AXI‑Lite / APB / Wishbone

---

## Known Notes / Limitations (Current MVP)
- Configuration is loaded using parallel inputs + `write_enable` (no bus protocol yet).
- Some RTL files do not use `.v` extension; compilation requires explicit file listing.

---

## License
MIT License — see `LICENSE`.
