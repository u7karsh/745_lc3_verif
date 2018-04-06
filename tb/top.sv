`define DEBUG
`define STALL_THRESH 1000
`define BASE_ADDR    16'h3000
`define DYN_INST_CNT 1000000
`define TOP_MONITOR

`include "types.sv"
`include "interface.sv"
`include "transaction.sv"
`include "agent.sv"
`include "monitor.sv"
`include "driver.sv"
`include "env.sv"
`include "test.sv"
`include "tests.sv"

module top();

// Based on args, select a testcase
`TEST test;

reg clk = 0;
wire Data_rd;
wire [15:0] Data_addr;
wire [15:0] Data_din;

// Clock generation
always #5 clk = ~clk;

// TODO: Why do we need pull down??
//pulldown(Data_din[0]);
//pulldown(Data_din[1]);
//pulldown(Data_din[2]);
//pulldown(Data_din[3]);
//pulldown(Data_din[4]);
//pulldown(Data_din[5]);
//pulldown(Data_din[6]);
//pulldown(Data_din[7]);
//pulldown(Data_din[8]);
//pulldown(Data_din[9]);
//pulldown(Data_din[10]);
//pulldown(Data_din[11]);
//pulldown(Data_din[12]);
//pulldown(Data_din[13]);
//pulldown(Data_din[14]);
//pulldown(Data_din[15]);

//pulldown(Data_addr[0]);
//pulldown(Data_addr[1]);
//pulldown(Data_addr[2]);
//pulldown(Data_addr[3]);
//pulldown(Data_addr[4]);
//pulldown(Data_addr[5]);
//pulldown(Data_addr[6]);
//pulldown(Data_addr[7]);
//pulldown(Data_addr[8]);
//pulldown(Data_addr[9]);
//pulldown(Data_addr[10]);
//pulldown(Data_addr[11]);
//pulldown(Data_addr[12]);
//pulldown(Data_addr[13]);
//pulldown(Data_addr[14]);
//pulldown(Data_addr[15]);
//pulldown(Data_rd);

assign lc3if.Data_rd   = Data_rd;
assign lc3if.Data_addr = Data_addr;
assign lc3if.Data_din  = Data_din;

// Fetch connections
assign monif.reset                  = lc3if.reset;
assign monif.FETCH.pc               = dut.Fetch.pc;
assign monif.FETCH.npc              = dut.Fetch.npc_out;
assign monif.FETCH.instrmem_rd      = dut.Fetch.instrmem_rd;

//decode connections
assign monif.DECODE.IR              = dut.Dec.IR;
assign monif.DECODE.E_Control       = dut.Dec.E_Control;
assign monif.DECODE.W_Control       = dut.Dec.W_Control;
assign monif.DECODE.Mem_Control     = dut.Dec.Mem_Control;
assign monif.DECODE.npc_out         = dut.Dec.npc_out;

//execute connections
assign monif.EXECUTE.aluout          = dut.Ex.aluout;
assign monif.EXECUTE.W_Control_out   = dut.Ex.W_Control_out;
assign monif.EXECUTE.Mem_Control_out = dut.Ex.Mem_Control_out;
assign monif.EXECUTE.M_Data          = dut.Ex.M_Data;
assign monif.EXECUTE.dr              = dut.Ex.dr;
assign monif.EXECUTE.sr1             = dut.Ex.sr1;
assign monif.EXECUTE.sr2             = dut.Ex.sr2;
assign monif.EXECUTE.NZP             = dut.Ex.NZP;
assign monif.EXECUTE.IR_Exec         = dut.Ex.IR_Exec;
assign monif.EXECUTE.pcout           = dut.Ex.pcout;

//writeback connections
assign monif.WB.psr                  = dut.WB.psr;
assign monif.WB.VSR1                 = dut.WB.d1;
assign monif.WB.VSR2                 = dut.WB.d2;

//MemAccess connections
assign monif.MEM.Data_addr           = dut.MemAccess.Data_addr;
assign monif.MEM.Data_rd             = dut.MemAccess.Data_rd;
assign monif.MEM.Data_din            = dut.MemAccess.Data_din;
assign monif.MEM.memout              = dut.MemAccess.memout;

//controller connections
assign monif.CTRLR.enable_updatePC  = dut.Ctrl.enable_updatePC; 
assign monif.CTRLR.enable_fetch     = dut.Ctrl.enable_fetch; 
assign monif.CTRLR.enable_decode    = dut.Ctrl.enable_decode; 
assign monif.CTRLR.enable_execute   = dut.Ctrl.enable_execute; 
assign monif.CTRLR.enable_writeback = dut.Ctrl.enable_writeback; 
assign monif.CTRLR.br_taken         = dut.Ctrl.br_taken; 
assign monif.CTRLR.bypass_alu_1     = dut.Ctrl.bypass_alu_1; 
assign monif.CTRLR.bypass_alu_2     = dut.Ctrl.bypass_alu_2; 
assign monif.CTRLR.bypass_mem_1     = dut.Ctrl.bypass_mem_1; 
assign monif.CTRLR.bypass_mem_2     = dut.Ctrl.bypass_mem_2; 
assign monif.CTRLR.mem_state        = dut.Ctrl.mem_state; 
assign monif.CTRLR.Instr_dout       = dut.Ctrl.Instr_dout;

// Interface instantiation
Lc3_dr_if lc3if( clk );
Lc3_mon_if monif( clk );

// Test
initial begin
   `ifdef TOP_MONITOR
      $monitor("%t [TOP] reset: %0b pc: %0x instrmem_rd: %0b instr_dout: %0x data_addr: %0x complete_instr: %0b complete_data: %0b data_dout: %0x data_rd: %0b data_din: %0x", $time, lc3if.reset, lc3if.pc, lc3if.instrmem_rd, lc3if.Instr_dout, lc3if.Data_addr, lc3if.complete_instr, lc3if.complete_data, lc3if.Data_dout, lc3if.Data_rd, lc3if.Data_din );
   `endif
   test = new( lc3if, monif, 65536 );
   test.run();
   $finish;
end

//--------------------------------------- DUT -----------------------------
LC3 dut(	.clock(lc3if.clk), 
         .reset(lc3if.reset), 
         .pc(lc3if.pc), 
         .instrmem_rd(lc3if.instrmem_rd), 
         .Instr_dout(lc3if.Instr_dout), 
         .Data_addr(Data_addr), 
         .complete_instr(lc3if.complete_instr), 
         .complete_data(lc3if.complete_data),  
         .Data_din(Data_din), 
         .Data_dout(lc3if.Data_dout), 
         .Data_rd(Data_rd)	);
endmodule
