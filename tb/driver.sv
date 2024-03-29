class Driver extends Agent;
   virtual Lc3_dr_if  driverIf;

   task run_fetch();
      integer dynInstCount    = 0;
      integer instMemIndex;
      integer stallCnt        = 0;
      // TODO: quick fix: 1st instruction is not being clocked
      // so clock it twice
      bit     redoInst        = 1;

      Instruction dInst;
      while(1) begin
         check( "DRIVER", FATAL, stallCnt < `STALL_THRESH, "instrmem_rd not gone high for set threshold" );

         if( driverIf.instrmem_rd ) begin
            stallCnt                 = 0;
            // Feeding in trace
            // To feed in asm, uncomment pc - base_addr
            instMemIndex             = dynInstCount; // driverIf.pc - `BASE_ADDR;
            if( !redoInst )
               dynInstCount         += 1;
            if( instMemIndex < 0 || instMemIndex >= getInstMemSize() ) begin
               $display("\t\tinstMemIndex: %0d, getInstMemSize: %0d", instMemIndex, getInstMemSize());
               $display("\t\tGracefully exitting testcase");
               break;
            end

            dInst                    = getInstIndex(instMemIndex);
   
            // Read from instMemIndex memory
            `ifdef DEBUG_BASIC
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

         redoInst                         = 0;
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
            `ifdef DEBUG_DRIVER
               $display("memread : 0x%0x -> %x", driverIf.Data_addr, driverIf.Data_dout);
            `endif
         end else if( driverIf.Data_rd == 0 && driverIf.Data_addr !== 16'bx ) begin //&& driverIf.Data_din != 16'bx ) begin
            `ifdef DEBUG_DRIVER
               $display("memwrite: 0x%0x -> %x", driverIf.Data_addr, driverIf.Data_din);
            `endif
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
      driverIf.Data_dout      = 0;
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
