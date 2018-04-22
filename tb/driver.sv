class Driver extends Agent;
   virtual Lc3_dr_if  driverIf;

   task run_fetch();
      integer dynInstCount    = 0;
      integer instMemIndex;
      integer stallCnt        = 0;

      Instruction dInst;
      while(1) begin
         check( "DRIVER", FATAL, stallCnt < `STALL_THRESH, "instrmem_rd not gone high for set threshold" );

         if( driverIf.instrmem_rd ) begin
            stallCnt                 = 0;
            dynInstCount            += 1;
            instMemIndex             = driverIf.pc - `BASE_ADDR;
            if( instMemIndex < 0 || instMemIndex >= getInstMemSize() || dynInstCount >= `DYN_INST_CNT )
               break;

            dInst                    = getInstIndex(instMemIndex);
   
            // Read from instMemIndex memory
            `ifdef DEBUG
               printInstMemIndex( instMemIndex );
            `endif
            driverIf.complete_instr       = 0;
            // Modelling fetch delay
            repeat($random % `T_FETCH_MAX) @(posedge driverIf.clk);
            driverIf.complete_instr       = 1;
            driverIf.Instr_dout           = dInst.encodeInst();
            `ifdef DEBUG_DRIVER
               $display("%t instout", $time);
            `endif
         end
         else
            stallCnt                     += 1;
   
         // One clock delay
         @(posedge driverIf.clk);
      end
   endtask

   task run_data();
      forever begin
         driverIf.complete_data           = 0;
         // Modelling data delay
         repeat($random % `T_DATA_MAX) @(posedge driverIf.clk);
         driverIf.complete_data           = 1;
         `ifdef DEBUG_DRIVER
            $display("%t dataout", $time);
         `endif

         // Data memory read/write handling
         if( driverIf.Data_rd ) begin
            driverIf.Data_dout            = readDataMem(driverIf.Data_addr);
         end else begin
            writeDataMem( driverIf.Data_addr, driverIf.Data_din );
         end

         // One clock delay
         @(posedge driverIf.clk);
      end
   endtask

   task run(); //{
      //---------- RESET PHASE --------
      driverIf.reset          = 1;
      driverIf.complete_instr = 0;
      driverIf.complete_data  = 0;
      driverIf.Instr_dout     = getInstIndex(0).encodeInst();
      repeat(2) @(posedge driverIf.clk);
      driverIf.reset          = 0;
   
      // Fork off fetch and data proc
      fork
         run_fetch();
         run_data();
      join_any
   endtask //}

   function new(virtual Lc3_dr_if  driverIf);
      super.new();
      this.driverIf  = driverIf;
   endfunction

endclass
