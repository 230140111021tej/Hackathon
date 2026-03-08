module motor_control_top #(
    parameter WIDTH = 12
)(
    input  wire clk,
    input  wire rst,

    input  wire start,
    input  wire emergency_stop,
    input  wire overcurrent,

    input  wire write_enable,

    input  wire [WIDTH-1:0] duty_a_in,
    input  wire [WIDTH-1:0] duty_b_in,
    input  wire [WIDTH-1:0] duty_c_in,

    input  wire [WIDTH-1:0] freq_in,
    input  wire [WIDTH-1:0] deadtime_in,

output wire fault_flag,
    output wire pwm_a_high,
output wire pwm_a_low,
output wire pwm_b_high,
output wire pwm_b_low,
output wire pwm_c_high,
output wire pwm_c_low
);

/////////////////////////////////////////////////
// Internal Signals
/////////////////////////////////////////////////

wire [WIDTH-1:0] duty_a;
wire [WIDTH-1:0] duty_b;
wire [WIDTH-1:0] duty_c;

wire [WIDTH-1:0] freq_div;
wire [WIDTH-1:0] deadtime;

wire control_reg;
wire fault_flag_internal;
wire fsm_pwm_enable;
wire fault_detect;

wire pwm_enable;

wire start_sync;
wire estop_sync;
wire overcurrent_sync;

/////////////////////////////////////////////////
// Input Synchronizers
/////////////////////////////////////////////////

sync_block sync_start (
    .clk(clk),
    .rst(rst),
    .async_in(start),
    .sync_out(start_sync)
);

sync_block sync_estop (
    .clk(clk),
    .rst(rst),
    .async_in(emergency_stop),
    .sync_out(estop_sync)
);

sync_block sync_overcurrent (
    .clk(clk),
    .rst(rst),
    .async_in(overcurrent),
    .sync_out(overcurrent_sync)
);

/////////////////////////////////////////////////
// Register Bank
/////////////////////////////////////////////////

register_bank #(
    .WIDTH(WIDTH)
) reg_bank_inst (

    .clk(clk),
    .rst(rst),
    .write_enable(write_enable),

    .duty_a_in(duty_a_in),
    .duty_b_in(duty_b_in),
    .duty_c_in(duty_c_in),

    .freq_in(freq_in),
    .deadtime_in(deadtime_in),

    .control_in(start_sync),

    .duty_a(duty_a),
    .duty_b(duty_b),
    .duty_c(duty_c),

    .freq_div(freq_div),
    .deadtime(deadtime),

    .control_reg(control_reg)
);

/////////////////////////////////////////////////
// Protection Unit
/////////////////////////////////////////////////

protection_unit protection_inst(

    .clk(clk),
    .rst(rst),

   .overcurrent(overcurrent_sync),
.emergency_stop(estop_sync),
    .system_enable(control_reg),

    .fault_detect(fault_detect)

);

/////////////////////////////////////////////////
// Control FSM
/////////////////////////////////////////////////

control_fsm fsm_inst(

    .clk(clk),
    .rst(rst),

    .start(start_sync),
    .fault_detect(fault_detect),

    .pwm_enable(fsm_pwm_enable),
.fault_flag(fault_flag_internal)

);
assign fault_flag = fault_flag_internal;
/////////////////////////////////////////////////
// Combine FSM + Protection
/////////////////////////////////////////////////

assign pwm_enable = fsm_pwm_enable & ~fault_detect;

/////////////////////////////////////////////////
// PWM Engine
/////////////////////////////////////////////////

pwm_engine #(
    .WIDTH(WIDTH)
) pwm_engine_inst(

    .clk(clk),
    .rst(rst),
    .enable(pwm_enable),

    .freq_div(freq_div),
.deadtime(deadtime),
.duty_a(duty_a),
.duty_b(duty_b),
.duty_c(duty_c),

.pwm_a_high(pwm_a_high),
.pwm_a_low(pwm_a_low),
.pwm_b_high(pwm_b_high),
.pwm_b_low(pwm_b_low),
.pwm_c_high(pwm_c_high),
.pwm_c_low(pwm_c_low)

);

endmodule
