class Coverage;
   virtual Lc3_mon_if monIf;

   covergroup ALU_OPR_cg @(posedge monIf.clk);
      opcode_arith: coverpoint top.test.env.monitor.currentTrans.opcode {
         bins Add    = {ADD};
         bins And    = {AND};
         bins Not    = {NOT};
      }

      opcode_branch: coverpoint top.test.env.monitor.currentTrans.opcode {
         bins br     = {BR};
         bins jmp    = {JMP};
      }

      opcode_load: coverpoint top.test.env.monitor.currentTrans.opcode {
         bins ld     = {LD};
         bins ldr    = {LDR};
         bins ldi    = {LDI};
         bins lea    = {LEA};
      }

      opcode_store: coverpoint top.test.env.monitor.currentTrans.opcode {
         bins st     = {ST};
         bins str    = {STR};
         bins sti    = {STI};
      }
   endgroup

   covergroup MEM_OPR_cg @(posedge monIf.clk);
   endgroup

   covergroup CTRL_OPR_cg @(posedge monIf.clk);
   endgroup

   covergroup OPR_SEQ_cg @(posedge monIf.clk);
   endgroup

   function new( virtual Lc3_mon_if monIf );
      this.monIf       = monIf;
      this.ALU_OPR_cg  = new;
      this.MEM_OPR_cg  = new;
      this.CTRL_OPR_cg = new;
      this.OPR_SEQ_cg  = new;
   endfunction

endclass
