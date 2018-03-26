//TODO: BUGS
// 1. JMP instruction not verified. Error: bad handling or reference. (PC issue)
// 2. Connectivity verif
module Drivemon( Lc3_dr_if lif, Lc3_mon_if monif );

wire clk;
assign clk            = lif.clk;

Instruction instMem[];
integer instMemIndex;
integer dynInstCount  = 0;
reg [15:0] dataMem[0:65536];

integer num_tests     = 0;
integer failed_tests  = 0;


task checkerFn(string stage, reg cond, string A);
   num_tests         += 1;
   if(!cond) begin
      failed_tests   += 1;
      $warning("%t [CHECKER.%s] %s", $time, stage, A);
   end
endtask

//--------------------------------- MONITOR BEGIN --------------------
//------------------------FETCH-------------
reg [15:0] fetch_pc;
reg [15:0] fetch_npc;
initial begin //{
   while(1) begin //{
      if( !lif.reset ) begin //{
         fetch_npc     = fetch_pc + 16'b1;
         checkerFn("FETCH", fetch_pc  == monif.FETCH.pc, $psprintf("PC not matched (%0x != %0x)", fetch_pc, monif.FETCH.pc) );
         checkerFn("FETCH", fetch_npc == monif.FETCH.npc, $psprintf("NPC not matched (%0x != %0x)", fetch_npc, monif.FETCH.npc) );
         checkerFn("FETCH", monif.CTRLR.enable_fetch == monif.FETCH.instrmem_rd,
                    $psprintf("instrmem_rd not matched (%0x != %0x)", monif.CTRLR.enable_fetch, monif.FETCH.instrmem_rd) );
         $display("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", $time, monif.FETCH.pc, monif.FETCH.npc, monif.FETCH.instrmem_rd);
         // Modelling 1 FF in PC
         fetch_pc      = (monif.CTRLR.enable_updatePC) ? ((monif.CTRLR.br_taken) ? monif.EXECUTE.pcout : fetch_npc) : fetch_pc;
      end//}
      else begin //{
         //reset phase
         fetch_pc      = `BASE_ADDR; 
      end //}
      @(posedge clk);
   end //}
end //}

//------------------------DECODE---------------
reg [5:0]  decode_Ectrl;
reg        decode_Mctrl;
reg [1:0]  decode_Wctrl;
reg [15:0] decode_ir, decode_npcout;

initial begin //{
   while(1) begin //{
      if( !lif.reset ) begin //{
         checkerFn("DECODE", decode_ir == monif.DECODE.IR, 
                   $psprintf("Unmatched IR (%0x != %0x, Opcode: %s != %s)", decode_ir, monif.DECODE.IR, 
                             Instruction::op2str(decode_ir[15:12]), 
                             Instruction::op2str(monif.DECODE.IR[15:12])) );

         case(decode_ir[15:12])
            Instruction::ADD: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b0, 2'bxx, 1'bx, !monif.DECODE.IR[5]}; end
            Instruction::AND: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b1, 2'bxx, 1'bx, !monif.DECODE.IR[5]}; end
            Instruction::NOT: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'd2, 2'bxx, 1'bx, 1'bx}; end
            Instruction::BR : begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            Instruction::JMP: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'd3, 1'b0, 1'bx}; end
            Instruction::LD : begin decode_Mctrl = 0; decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            Instruction::LDR: begin decode_Mctrl = 0; decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx}; end
            Instruction::LDI: begin decode_Mctrl = 1; decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            Instruction::LEA: begin decode_Mctrl = 1'bx; decode_Wctrl = 2; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            Instruction::ST : begin decode_Mctrl = 0; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            Instruction::STR: begin decode_Mctrl = 0; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx}; end
            Instruction::STI: begin decode_Mctrl = 1; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
         endcase

         checkerFn("DECODE", decode_Ectrl == monif.DECODE.E_Control, $psprintf("[%s] E_control unmatched! (%0x != %0x)", 
                                                   Instruction::op2str(decode_ir[15:12]), decode_Ectrl, monif.DECODE.E_Control));
         checkerFn("DECODE", decode_Wctrl == monif.DECODE.W_Control, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
                                                   Instruction::op2str(decode_ir[15:12]), decode_Wctrl, monif.DECODE.W_Control));
         checkerFn("DECODE", decode_Mctrl == monif.DECODE.Mem_Control, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
                                                   Instruction::op2str(decode_ir[15:12]), decode_Mctrl, monif.DECODE.Mem_Control));

         decode_ir  = monif.CTRLR.enable_decode ? monif.CTRLR.Instr_dout : decode_ir;
         $display("%t [MON.decode] %0b E_Control: %0x, %0x, %0x, %0x", $time, monif.DECODE.IR[15:12], monif.DECODE.E_Control[5:4], 
                                                       monif.DECODE.E_Control[3:2], monif.DECODE.E_Control[1], monif.DECODE.E_Control[0]);
      end //}
      @(posedge clk);
   end //}
end //}
//---------------------------------- MONITOR END ---------------------

//---------------------------------- DRIVER BEGIN --------------------
initial begin
   //---------- RESET PHASE --------
   lif.reset          = 1;
   lif.complete_instr = 0;
   lif.complete_data  = 0;
   repeat(2) @(posedge clk);
   lif.reset          = 0;

   // Process each instMemion
   while(1) begin
      if( lif.instrmem_rd ) begin
         dynInstCount            += 1;
         instMemIndex             = lif.pc - `BASE_ADDR;
         if( instMemIndex >= instMem.size() || dynInstCount >= `DYN_INST_CNT )
            break;

         // Read from instMemIndex memory
         `ifdef DEBUG
            instMem[instMemIndex].print();
         `endif
         lif.complete_instr       = 1;
         lif.Instr_dout           = instMem[instMemIndex].encodeInst();
      end

      // Data memory read/write handling
      if( lif.Data_rd ) begin
         lif.complete_data        = 1;
         lif.Data_dout            = dataMem[ lif.Data_addr ];
      end else begin
         dataMem[ lif.Data_addr ] = lif.Data_din;
      end

      // One clock delay
      @(posedge clk);
   end
   $display("----------- END OF TEST -------------");
   $display("----------- BEGIN REPORT ------------");
   $display("Stats: %0d / %0d Evaluations Failed", failed_tests, num_tests);
   if(!failed_tests)
      $display("ALL TEST CASES PASSED!!!!!");
   else
      $display("YO DAWG! YOU GOT SOME %0d FAILED TEST CASES. SORRY BRUH!", failed_tests);

   $display("------------ END REPORT -------------\n");
   $finish;
end
//----------------------------------- DRIVER END ---------------------

endmodule
