# Hackathon
# Motor Control IP (Hackathon MVP) — 3‑Phase PWM + Protection + FPGA Results

This repository contains an RTL **Motor Control IP** developed for the **Industrial & Automotive IP Development (Track B: Motor Control IP)** hackathon theme.

The IP provides a **functional MVP** featuring:
- **3‑phase PWM generation** (A/B/C phases)
- **Configurable duty cycle and frequency**
- **Basic protection** (overcurrent + emergency stop)
- **FPGA/ASIC‑oriented modular architecture** (Control Path + Data Path)
- **Simulation testbench + waveform validation**
- **FPGA implementation results (timing/power/resource)**

---

## 1. MVP Requirements Checklist (Track B)

| Requirement | Implemented? | Notes |
|---|---:|---|
| 3‑phase PWM generation | ✅ | Complementary `high/low` outputs for A/B/C |
| Configurable duty cycle | ✅ | `duty_a_in`, `duty_b_in`, `duty_c_in` captured into registers |
| Configurable frequency | ✅ | `freq_in` → `freq_div` sets counter maximum |
| Basic protection logic | ✅ | `overcurrent` / `emergency_stop` produce `fault_detect`; PWM gated off |

---

## 2. Top-Level Module

**Top module:** `motor_control_top`  
File: `Codes/Motor_Control_Top.v`

### Inputs
- `clk` : system clock  
- `rst` : asynchronous reset
- `start` : start/enable request (synchronized internally)
- `emergency_stop` : emergency stop input (synchronized internally)
- `overcurrent` : fault input (synchronized internally)
- `write_enable` : captures configuration into the register bank
- `duty_a_in`, `duty_b_in`, `duty_c_in` : PWM duty settings (WIDTH bits)
- `freq_in` : PWM period control / counter max (WIDTH bits)
- `deadtime_in` : deadtime in **clock cycles** (WIDTH bits)

### Outputs
- `fault_flag` : fault indication from FSM
- `pwm_a_high`, `pwm_a_low`
- `pwm_b_high`, `pwm_b_low`
- `pwm_c_high`, `pwm_c_low`

### Key Behavior
- Async inputs are synchronized using a 2‑FF synchronizer.
- Configuration registers update when `write_enable = 1`.
- PWM enable is controlled by the FSM and blocked by protection:
  - `pwm_enable = fsm_pwm_enable & ~fault_detect`

---

## 3. Architecture Overview (Control Path vs Data Path)

### Control Path
Located in: `Codes/Control_Path/`

- **`sync_block`**  
  2‑flip‑flop synchronizer for async inputs (`start`, `overcurrent`, `emergency_stop`).

- **`protection_unit`**  
  Detects and latches fault when:
  - `overcurrent == 1` OR `emergency_stop == 1`  
  Fault is used to disable PWM.

- **`control_fsm`**  
  Simple FSM with states such as `IDLE`, `RUN`, `FAULT`, `RESET` to drive:
  - `pwm_enable`
  - `fault_flag`

### Data Path
Located in: `Codes/Data_Path/`

- **`register_bank`**  
  Captures and stores:
  - `duty_a`, `duty_b`, `duty_c`
  - `freq_div`
  - `deadtime`
  - `control_reg`

- **`pwm_engine`**  
  Generates PWM in stages:
  1. `pwm_counter` creates a ramp counter from 0..`freq_div`
  2. `compare_logic` generates raw PWM (`pwm_*_raw`) using `(counter < duty)`
  3. `deadtime_block` produces complementary `high/low` outputs with deadtime

---

## 4. PWM Operation Details

### Raw PWM (per phase)
For each phase:
- `pwm_raw = 1` when `counter < duty`
- `pwm_raw = 0` otherwise

This produces **edge-aligned PWM**.

### Counter / Frequency
- The counter counts upward while enabled.
- It resets to `0` when `count >= freq_div`.
- Therefore the PWM period is approximately **(freq_div + 1) clock cycles**.

### Deadtime
- `deadtime` is specified in **clock cycles**.
- The `deadtime_block` holds both outputs OFF for the programmed deadtime during switching, then enables the complementary output.

---

## 5. Verification (Testbench + Waveforms)

A simulation testbench is included to validate:
- FSM transitions (`IDLE` → `RUN` → `FAULT` behavior)
- Fault response (PWM disabled on `overcurrent` / `emergency_stop`)
- Counter behavior vs `freq_div`
- Duty cycle comparison output (`pwm_*_raw`)
- Deadtime behavior (`pwm_*_high`, `pwm_*_low` never overlap; deadtime gap visible)

**Waveform evidence:**  
The provided waveforms show:
- State transitions and fault handling (`fault_detect`, `fault_flag`, `pwm_enable`)
- PWM generation chain (counter → raw PWM → high/low with deadtime)
- Register updates through `write_enable`
- Synchronizer behavior (`async_in` → `sync_ff1` → `sync_out`)

> Note: If you are submitting to a judging panel, include these waveform screenshots in your report/PPT as proof of functional correctness.

---

## 6. FPGA Implementation Results (Vivado)

### Resource Utilization (Implementation)
- **LUT:** ~**87**
- **FF:** ~**84**
- **BRAM:** **0**
- **DSP:** **0**
- (Very compact logic footprint suitable for scaling or integration.)

### Timing (Implemented Design)
- **WNS (Setup):** **+4.671 ns**
- **TNS:** **0.000 ns**
- **Failing endpoints:** **0**
- **WHS (Hold):** **+0.183 ns**
- **Pulse width slack:** **+4.500 ns**
- Result: **All user-specified timing constraints are met.**

### Power (Implemented Design)
- **Total on‑chip power:** **0.076 W**
  - **Static:** **0.072 W (94%)**
  - **Dynamic:** **0.004 W (6%)**
- Dynamic power breakdown indicates I/O dominates dynamic portion.
- **Power confidence level:** Low (vectorless estimation / limited activity data).

### Notes on Vivado Warnings
Vivado reports warnings mainly related to missing I/O delay constraints (TIMING‑18) and configuration voltage properties (CFGBVS/CONFIG_VOLTAGE). These are **constraints / board setup items**, not functional RTL errors.

---

## 7. How to Run (Simulation)

### Option A: Icarus Verilog (example)
Update paths to match your repo layout.

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
  tb/tb_motor_control_top.v

vvp sim.out
```

### Option B: Vivado Simulation
- Add all RTL files + testbench in Vivado
- Run Behavioral Simulation
- Observe waveforms for PWM, faults, and deadtime

---

## 8. Roadmap (Advanced Enhancements)
Conceptual roadmap beyond MVP (for industrial / EV‑grade motor control IP):
- Sensorless control (Back‑EMF observer / PLL / SMO)
- Torque estimation (current + speed + motor model)
- Closed-loop architecture (current loop + speed loop; PI controllers)
- Improved fault handling:
  - sticky fault registers, explicit fault clear
  - undervoltage/overvoltage/thermal faults
- Standard register interface for integration:
  - AXI‑Lite / APB / Wishbone
- Add formal checks / assertions + functional coverage

---

## License
MIT License — see `LICENSE`.
