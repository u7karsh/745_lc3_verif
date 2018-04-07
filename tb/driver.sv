class Driver extends Agent;
   virtual Lc3_dr_if  driverIf;

   task run(); //{
      integer dynInstCount    = 0;
      integer instMemIndex;
      integer stallCnt        = 0;

      //---------- RESET PHASE --------
      driverIf.reset          = 1;
      driverIf.complete_instr = 0;
      driverIf.complete_data  = 0;
      driverIf.Instr_dout     = getInstIndex(0).encodeInst();
      repeat(2) @(posedge driverIf.clk);
      driverIf.reset          = 0;
   
      // Process each instMemion
      while(1) begin
         check( "DRIVER", FATAL, stallCnt < `STALL_THRESH, "instrmem_rd not gone high for set threshold" );

         if( driverIf.instrmem_rd ) begin
            stallCnt                 = 0;
            dynInstCount            += 1;
            instMemIndex             = driverIf.pc - `BASE_ADDR;
            if( instMemIndex >= getInstMemSize() || dynInstCount >= `DYN_INST_CNT )
               break;
   
            // Read from instMemIndex memory
            `ifdef DEBUG
               printInstMemIndex( instMemIndex );
            `endif
            driverIf.complete_instr       = 1;
            driverIf.Instr_dout           = getInstIndex(instMemIndex).encodeInst();
         end
         else
            stallCnt                     += 1;
   
         // Data memory read/write handling
         if( driverIf.Data_rd ) begin
            driverIf.complete_data        = 1;
            driverIf.Data_dout            = readDataMem(driverIf.Data_addr);
         end else begin
            writeDataMem( driverIf.Data_addr, driverIf.Data_din );
            driverIf.complete_data        = 1;
         end
   
         // One clock delay
         @(posedge driverIf.clk);
         //driverIf.complete_instr          = 0;
         //driverIf.complete_data           = 0;
      end
   endtask //}

   function new(virtual Lc3_dr_if  driverIf);
      super.new();
      this.driverIf  = driverIf;
   endfunction

endclass
