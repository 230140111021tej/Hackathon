# Motor Control IP (Hackathon MVP) — 3‑Phase PWM + Protection + FPGA Proof

**Track:** Industrial & Automotive IP Development → **Track B: Motor Control IP**  
**Objective:** Motor-control oriented IP core suitable for industrial drives / EV subsystems (MVP)

This repository implements a **hardware-oriented (FPGA/ASIC-friendly) 3-phase PWM Motor Control IP** with:
- configurable duty and frequency control
- complementary high/low gate outputs with deadtime insertion
- basic fault protection (overcurrent, emergency stop)
- simulation testbench + waveform generation
- FPGA implementation proof (timing/power/utilization)

---

## Hackathon MVP Requirements Coverage

| MVP Requirement | Status | Implementation Notes |
|---|---:|---|
| 3‑phase PWM generation | ✅ | `pwm_a_*`, `pwm_b_*`, `pwm_c_*` outputs |
| Configurable duty cycle | ✅ | `duty_a_in/b_in/c_in` captured into internal regs |
| Configurable frequency control | ✅ | `freq_in` → `freq_div` controls PWM counter max |
| Basic protection logic | ✅ | `overcurrent`/`emergency_stop` → `fault_detect`, PWM gated off |

---

## Repository Structure

- `Codes/`
  - `Motor_Control_Top.v` — top-level integration (`motor_control_top`)
  - `Control_Path/`
    - `Sync_Block` — 2‑FF synchronizer for async inputs
    - `Protection_Unit` — fault detection / latch
    - `Control_Fsm` — FSM generating PWM enable + fault flag
  - `Data_Path/`
    - `Register_Bank` — configuration registers (duty/freq/deadtime/control)
    - `Pwm_Engine` — counter + compare + deadtime output generation
    - `Sub_Modules/`
      - `Pwm_Counter`
      - `Compare_Logic`
      - `Deadtime_Block`
- `Testbench` — simulation testbench (dumps `motor_control.vcd`)
- `Images/` — proof screenshots (Vivado timing/power/utilization + datapath/controlpath diagrams)
- `LICENSE` — MIT License

---

## Top-Level Module

**Top:** `motor_control_top`  
**File:** `Codes/Motor_Control_Top.v`  
**Parameter:** `WIDTH` (default 12)

### Inputs
- Clock/Reset:
  - `clk`
  - `rst` (async reset)
- Control (asynchronous external signals; internally synchronized):
  - `start`
  - `emergency_stop`
  - `overcurrent`
- Configuration capture:
  - `write_enable`
  - `duty_a_in [WIDTH-1:0]`
  - `duty_b_in [WIDTH-1:0]`
  - `duty_c_in [WIDTH-1:0]`
  - `freq_in [WIDTH-1:0]` (PWM counter max)
  - `deadtime_in [WIDTH-1:0]` (deadtime in clock cycles)

### Outputs
- Status:
  - `fault_flag`
- PWM gate outputs:
  - `pwm_a_high`, `pwm_a_low`
  - `pwm_b_high`, `pwm_b_low`
  - `pwm_c_high`, `pwm_c_low`

---

## Architecture (Data Path vs Control Path)

### Control Path
- Synchronizes async inputs using `sync_block`
- Detects faults using `protection_unit`
- Runs `control_fsm` to enable/disable PWM and raise `fault_flag`
- Final enable is gated by fault detection:
  - `pwm_enable = fsm_pwm_enable & ~fault_detect`

### Data Path
- `register_bank` stores the configuration when `write_enable=1`
- `pwm_engine` generates PWM outputs:
  1) `pwm_counter`: `count` ramp from 0..`freq_div`  
  2) `compare_logic`: raw PWM: `(counter < duty_x)`  
  3) `deadtime_block`: creates complementary `high/low` with deadtime

### Cross-path signals
- **Control → Data:** `pwm_enable`
- (Optional/config capture in current top): `control_in` (= synchronized start) into `register_bank`
- **Data → Control:** none in current MVP

---

## PWM Operation Notes

### Duty behavior
Per phase: `pwm_raw = (counter < duty)` (edge-aligned PWM).

### Frequency behavior
- Counter resets when `count >= freq_div`
- PWM period ≈ `(freq_div + 1)` clock cycles

### Deadtime
- `deadtime` is in **clock cycles**
- `deadtime_block` inserts a gap where both outputs are OFF during switching

---

## Verification (Simulation)

A testbench is provided in `Testbench`. It:
- applies reset
- loads configuration (`write_enable`)
- starts PWM
- changes duty during run
- changes frequency
- injects faults (overcurrent and emergency_stop)
- applies stress values (0% / 100% duty, larger deadtime)

### Outputs generated
- Waveform dump: `motor_control.vcd`

### Run with Icarus Verilog
> Note: some RTL files have no `.v` extension, but they are Verilog modules.

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
gtkwave motor_control.vcd
```

---

## FPGA Implementation Proof (Vivado)

Screenshots are available in `Images/`:
- `Images/design_runs.png` (synth + route complete)
- `Images/Timing_report.png` (timing summary)
- `Images/Power_report.png` (power summary)

### Resource utilization (implementation)
- LUT: ~87  
- FF: ~84  
- BRAM: 0  
- DSP: 0  

### Timing summary (implemented)
- WNS (setup): +4.671 ns
- WHS (hold): +0.183 ns
- Failing endpoints: 0
- All user-specified constraints met

### Power summary (implemented)
- Total on-chip power: 0.076 W
  - Static: 0.072 W (94%)
  - Dynamic: 0.004 W (6%)

---

## Roadmap (Advanced Enhancements)

Conceptual next steps toward industrial/EV-grade motor control:
- Sensorless control strategy (back-EMF observer / SMO / PLL)
- Torque estimation algorithm (model-based, using current/speed estimates)
- Closed-loop control architecture (current loop + speed loop; PI control)
- Enhanced fault handling:
  - sticky fault registers + explicit fault clear
  - fault codes (overcurrent vs estop, etc.)
- Standard integration interface:
  - AXI‑Lite / APB / Wishbone register map

---

## License
MIT License — see `LICENSE`.
