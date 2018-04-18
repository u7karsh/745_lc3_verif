//interface Lc3_dr_if(clk, reset); 
interface Lc3_dr_if(input bit clk);
   logic        reset;
   logic        complete_instr, complete_data;
   logic [15:0] pc, Data_addr;
   logic        instrmem_rd, Data_rd;
   logic [15:0] Instr_dout, Data_dout;
   logic [15:0] Data_din;
endinterface

interface Lc3_mon_if( input logic        clk,

                      //fetch
                      input logic        reset,
                      input logic [15:0] npc,
                      input logic [15:0] pc,
                      input logic        instrmem_rd,

                      //decode
                      input logic [15:0] IR, npc_out,
                      input logic [5:0]  E_Control,
                      input logic [1:0]  W_Control,
                      input logic        Mem_Control,

                      //execute
                      input logic [15:0] aluout, pcout, IR_Exec, M_Data,
                      input logic [1:0]  W_Control_out,
                      input logic        Mem_Control_out,
                      input logic [2:0]  dr, sr1, sr2, NZP,

                      //writeback
                      input logic [2:0]  psr,
                      input logic [15:0] VSR1, VSR2,

                      //MemAccess
                      input logic [15:0] Data_addr, Data_din, memout,
                      input logic        Data_rd,

                      //controller
                      input logic        enable_updatePC, enable_fetch, enable_decode, 
                      input logic        enable_execute, enable_writeback, br_taken, 
                      input logic        bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, 
                      input logic [1:0]  mem_state,
                      input logic [15:0] Instr_dout
                    );

   modport FETCH(output npc, pc, instrmem_rd);
   modport DECODE(output IR, E_Control, npc_out, Mem_Control, W_Control);
   modport EXECUTE(output aluout, W_Control_out, Mem_Control_out, M_Data, dr, sr1, sr2, NZP, IR_Exec, pcout);
   modport WB(output psr, VSR1, VSR2);
   modport MEM(output Data_addr, Data_rd, Data_din, memout);
   modport CTRLR(output enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback, 
                   br_taken, bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, mem_state, Instr_dout);
endinterface
