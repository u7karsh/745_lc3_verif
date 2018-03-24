interface Lc3_if ( input bit clk );
   logic        reset;
   logic        complete_instr, complete_data;
   logic [15:0] pc, Data_addr;
   logic        instrmem_rd, Data_rd;
   logic [15:0] Instr_dout, Data_dout;
   logic [15:0] Data_din;
endinterface
