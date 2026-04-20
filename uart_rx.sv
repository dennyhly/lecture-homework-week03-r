`include "clock_mul.sv"

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// STATES: State of the state machine
localparam DATA_BITS = 8;
typedef enum logic [3:0]{INIT, IDLE, RX_DATA, STOP} state_t;
state_t state = INIT;

// CLOCK MULTIPLIER: Instantiate the clock multiplier
logic uart_clk;
clock_mul #(
    .SRC_FREQ(SRC_FREQ),
    .OUT_FREQ(BAUDRATE)
) clk_mul (
    .src_clk(clk),
    .out_clk(uart_clk)
);

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.
logic sync_ff1, sync_ff2;

always @(posedge clk) begin
    sync_ff1 <= rx_ready;
    sync_ff2 <= sync_ff1;
    rx_ready <= sync_ff1 & sync_ff2;
end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal
logic [2:0] rx_counter;

always @(posedge uart_clk) begin
    case (state)
        INIT: begin state <= IDLE; rx_counter <= 0; rx_ready <= 0; rx_data <= 0; end

        IDLE: begin 
            if (rx == 0) begin state <= RX_DATA; rx_counter <= 0;end
            else begin state <= IDLE; end
        end

        RX_DATA: begin
            rx_data[rx_counter] <= rx;
            if (rx_counter < DATA_BITS - 1) begin rx_counter <= rx_counter + 1; state <= RX_DATA; end
            else begin rx_counter <= 0; state <= STOP; end
        end

        STOP: begin
            if (rx) begin state <= IDLE; rx_ready <= ~rx_ready; end
            else begin state <= STOP; end
        end
        default: state = INIT;
    endcase
end

endmodule