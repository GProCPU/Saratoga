//cmd cd ${PROJ_DIR}/sw/projects/blink && make build dump
//cmd cp ${PROJ_DIR}/sw/projects/blink/rom.hex .
`timescale 1ns/1ps


module soc_TB;

    localparam MAX_CYCLES = 256;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;
    logic mutex;

    // DUT Ports
    // inputs
    logic clk;
    logic rst;
    // GPIO
    wire [47:0] io_pins;

    assign rst_n = ~rst;


    // Instantiate DUT
    saratoga_soc DUT (
        .clk,
        .rst,
        .io_pins
    );


    // 10 MHz clock
    initial clk = 1;
    initial forever #50 clk = ~clk;

    // Initialize
    initial begin
        fid = $fopen("soc.log");
        $dumpfile("soc.vcd");
        $dumpvars(4, soc_TB);

        // Reset
        rst <= 1;
        #200;
        rst <= 0;
    end


    // Stimulus
    initial begin
        // nothing, only program output
    end


    // End Simulation
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail) begin
                $write("\n\nFAILED %d tests\n", fail);
                $fwrite(fid,"\n\nFailed %d tests\n", fail);
            end
            else begin
                $write("\n\nPASSED all tests\n");
                $fwrite(fid,"\n\nPASSED all tests\n");
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule