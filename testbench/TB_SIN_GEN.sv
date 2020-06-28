/*=============================================================================
 * Title        : SIN wave generator testbench
 *
 * File Name    : TB_SIN_GEN.sv
 * Project      : 
 * Designer     : toms74209200 <https://github.com/toms74209200>
 * Created      : 2020/06/24
 * License      : MIT License.
                  http://opensource.org/licenses/mit-license.php
 *============================================================================*/

`timescale 1ns/1ns

`define MessageOK(variable) \
$messagelog("%:S %:F(%:L) OK:Assertion %:O.", "Note", `__FILE__, `__LINE__, variable);
`define MessageERROR(variable) \
$messagelog("%:S %:F(%:L) ERROR:Assertion %:O failed.", "Error", `__FILE__, `__LINE__, variable);
`define ChkValue(variable, value) \
    if ((variable)===(value)) \
        `MessageOK(variable) \
    else \
        `MessageERROR(variable)

module TB_SIN_GEN ;

// Simulation module signal
bit         RESET_n;            //(n) Reset
bit         CLK;                //(p) Clock
bit         ASI_READY = 0;      //(p) Avalon-ST sink data ready
bit         ASI_VALID = 0;      //(p) Avalon-ST sink data valid
bit [15:0]  ASI_DATA  = 0;      //(p) Avalon-ST sink data
bit         ASO_VALID;          //(p) Avalon-ST source data valid
bit [15:0]  ASO_DATA;           //(p) Avalon-ST source data
bit         ASO_ERROR;          //(p) Avalon-ST source error

// Parameter
parameter ClkCyc    = 10;       // Signal change interval(10ns/50MHz)
parameter ResetTime = 20;       // Reset hold time

// Data rom
bit [31:0] fibonacci_data_rom[1:47];

// module
SIN_GEN U_SIN_GEN(
.*,
.ASI_READY(ASI_READY),
.ASI_VALID(ASI_VALID),
.ASI_DATA(ASI_DATA),
.ASO_VALID(ASO_VALID),
.ASO_DATA(ASO_DATA),
.ASO_ERROR(ASO_ERROR)
);

/*=============================================================================
 * Clock
 *============================================================================*/
always begin
    #(ClkCyc);
    CLK = ~CLK;
end


/*=============================================================================
 * Reset
 *============================================================================*/
initial begin
    #(ResetTime);
    RESET_n = 1;
end 


/*=============================================================================
 * Signal initialization
 *============================================================================*/
initial begin
    ASI_VALID = 1'b0;
    ASI_DATA = 16'd0;

    #(ResetTime);
    @(posedge CLK);

/*=============================================================================
 * Normal data check
 *============================================================================*/
    $display("%0s(%0d)Normal data check", `__FILE__, `__LINE__);
    // wait(ASI_READY);
    ASI_DATA = 0;
    ASI_VALID = 1'b1;
    @(posedge CLK);
    for (int i=1;i<2048;i++) begin
        @(posedge CLK);
    end

    $finish;
end

endmodule
// TB_FIB
