`ifndef __SARATOGA_SV
`define __SARATOGA_SV

`include "rv32.sv"


package saratoga;

    localparam DEFAULT_CLK_PERIOD       = 10;               // core clock period in ns

    localparam DEFAULT_ROM_ADDR_WIDTH   = 10;               // word-addressable ROM address bits
    localparam DEFAULT_RAM_ADDR_WIDTH   = 10;               // word-addressable RAM address bits
    localparam DEFAULT_AXI_ADDR_WIDTH   = 29;               // byte-addressable AXI address space bits
    localparam MTIME_ADDR_WIDTH         = 4;                // byte-addressable machine timer address bits
    localparam GPTIM_ADDR_WIDTH         = 4;                // byte-addressable general-purpose timer address bits
    localparam UART_ADDR_WIDTH          = 2;                // byte-addressable UART address bits
    localparam GPIO_ADDR_WIDTH          = 4;                // byte-addressable GPIO address bits

    // The following addresses are byte-addressable in the 32-bit address space
    localparam DEFAULT_RESET_ADDR       = 32'h0000_0000;    // program counter reset/boot address
    localparam DEFAULT_ROM_BASE_ADDR    = 32'h0000_0000;    // must be aligned to ROM size
    localparam DEFAULT_RAM_BASE_ADDR    = 32'h4000_0000;    // must be aligned to RAM size
    localparam DEFAULT_MTIME_BASE_ADDR  = 32'hC000_0000;    // see CSR documentation
    localparam DEFAULT_AXI_BASE_ADDR    = 32'hE000_0000;    // must be aligned to AXI address space
    localparam TIM0_BASE_ADDR           = 32'hFFFF_FF0F;    // TIM0
    localparam TIM1_BASE_ADDR           = 32'hFFFF_FF1F;    // TIM1
    localparam UART0_BASE_ADDR          = 32'hFFFF_FF7F;    // UART0
    localparam GPIOA_BASE_ADDR          = 32'hFFFF_FFA0;    // GPIOA
    localparam GPIOB_BASE_ADDR          = 32'hFFFF_FFB0;    // GPIOB
    localparam GPIOC_BASE_ADDR          = 32'hFFFF_FFC0;    // GPIOC

    localparam DEFAULT_AXI_TIMEOUT      = 17;               // bus timeout in number of cycles
    localparam MTVEC_ADDR_BIT_ALIGN     = 7;                // alignment constraint for trap-vector addressing

    // Pipeline stage indexes
    localparam FETCH_STAGE_ID           = 0;
    localparam DECODE_STAGE_ID          = 1;
    localparam EXEC_STAGE_ID            = 2;


    localparam ALU_OP_WIDTH     = 4;                // ALU operation select width
    typedef enum logic [ALU_OP_WIDTH-1:0] {
        ALU_ADD  = 4'b0000,
        ALU_SLL  = 4'b0001,
        ALU_SLTU = 4'b0010,
        ALU_SGEU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SRL  = 4'b0101,
        ALU_OR   = 4'b0110,
        ALU_AND  = 4'b0111,
        ALU_SUB  = 4'b1000,
        /*reserved*/
        ALU_SLT  = 4'b1010,
        ALU_SGE  = 4'b1011,
        /*reserved*/
        ALU_SRA  = 4'b1101,
        /*reserved*/
        ALU_NOP  = 4'b1111
    } alu_op_t;


    localparam LSU_OP_WIDTH     = 4;                // LSU operation select width
    typedef enum logic [LSU_OP_WIDTH-1:0] {
        LSU_LB      = 4'b0000,
        LSU_LH      = 4'b0001,
        LSU_LW      = 4'b0010,
        /*reserved 64-bit*/
        LSU_LBU     = 4'b0100,
        LSU_LHU     = 4'b0101,
        /*reserved 64-bit*/
        /*reserved*/
        LSU_SB      = 4'b1000,
        LSU_SH      = 4'b1001,
        LSU_SW      = 4'b1010,
        /*reserved 64-bit*/
        LSU_CSRR    = 4'b1100,
        LSU_CSRRW   = 4'b1101,
        LSU_REG     = 4'b1110,
        LSU_NOP     = 4'b1111
    } lsu_op_t;


    // Implementation Specific Interrupts
    localparam TRAP_CODE_UART0RX                = 16;       // UART 0 RX interrupt(\s*).*axi_m.(\w*\s*).*
    localparam TRAP_CODE_UART0TX                = 17;       // UART 0 TX interrupt
    localparam TRAP_CODE_TIM0                   = 18;       // general-purpose timer 0 interrupt
    localparam TRAP_CODE_TIM1                   = 19;       // general-purpose timer 1 interrupt
    localparam TRAP_CODE_GPIOA0                 = 20;       // GPIO A interrupt 0
    localparam TRAP_CODE_GPIOA1                 = 21;       // GPIO A interrupt 1
    localparam TRAP_CODE_GPIOB0                 = 22;       // GPIO B interrupt 0
    localparam TRAP_CODE_GPIOB1                 = 23;       // GPIO B interrupt 1
    localparam TRAP_CODE_GPIOC0                 = 24;       // GPIO C interrupt 0
    localparam TRAP_CODE_GPIOC1                 = 25;       // GPIO C interrupt 1


    // Interrupt CSR typedef
    typedef struct packed {
        logic [5:0] reserved31_26;      // 31:26
        logic GPIOC1;                   // 25
        logic GPIOC0;                   // 24
        logic GPIOB1;                   // 23
        logic GPIOB0;                   // 22
        logic GPIOA1;                   // 21
        logic GPIOA0;                   // 20
        logic TIM1;                     // 19
        logic TIM0;                     // 18
        logic UART0TX;                  // 17
        logic UART0RX;                  // 16
        logic [3:0] reserved15_12;      // 15:12
        logic MEI;                      // 11
        logic reserved10;               // 10
        logic SEI;                      // 9
        logic reserved8;                // 8
        logic MTI;                      // 7
        logic reserved6;                // 6
        logic STI;                      // 5
        logic reserved4;                // 4
        logic MSI;                      // 3
        logic reserved2;                // 2
        logic SSI;                      // 1
        logic reserved0;                // 0
    } interrupt_csr_t;


    function automatic rv32::word convert_endian(rv32::word data);
        convert_endian = {data[7:0], data[15:8], data[23:16], data[31:24]};
    endfunction

    function automatic logic [15:0] convert_endian16(logic [15:0] data);
        convert_endian16 = {data[7:0], data[15:8]};
    endfunction

endpackage

`endif //__SARATOGA_SV
