class Test; //{
   // Interfaces
   virtual Lc3_dr_if  driverIf;
   virtual Lc3_mon_if monIf;
   Env                env;
   integer            instCnt = 0;
   string             name;

   // The following variables are used to check > 1 control/memory
   // instructions in the pipeline
   // This is due to the limitation of lc3 DUT
   integer            ctrlCounter;
   integer            memCounter;

   // Populates env's instruct mem
   // This is the base function that will be overridden in
   // all tests. It doesn't have LD/SD and BR as mem warmup
   // is not done
   virtual function void sequenceInstr();
      integer numTrans             = 8 + 10;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];
      for( int i = 0; i < 8; i++ ) begin
         instMemEntry.create(AND, 7-i, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end
      for( int i = 0; i < numTrans - 8; i++ ) begin
         if( instMemEntry.randomize() with { opcode inside {ADD, /*BR,*/ AND, NOT/*, LD, LDR, LDI, LEA, ST, STI, STR*/}; } ) begin
            pushInst(instMemEntry);
         end else begin
            $fatal(1, "Failed to randomize instMemEntry");
            eos(0);
         end
      end
   endfunction

   function void displayInstr();
      for( int i = 0; i < instCnt; i++ )
         top.test.env.instMem[i].print();
   endfunction

   function void pushInst( Instruction inst );
      if( instCnt < env.instMem.size() ) begin
         ctrlCounter          += 1;
         memCounter           += 1;

         // Control inst in pipeline check
         if( inst.isCtrl() ) begin
            if( ctrlCounter < `LC3_PIPE_DEPTH ) begin
               $fatal(1, "More than 1 control instruction in pipeline");
               eos(0);
            end
            ctrlCounter        = 0;
         end

         // Memory inst in pipeline check
         if( inst.isMem() ) begin
            if( memCounter < `LC3_PIPE_DEPTH ) begin
               $fatal(1, "More than 1 memory instruction in pipeline");
               eos(0);
            end
            memCounter         = 0;
         end

         // Saturate it
         ctrlCounter           = (ctrlCounter > `LC3_PIPE_DEPTH) ? `LC3_PIPE_DEPTH : ctrlCounter;
         memCounter            = (memCounter > `LC3_PIPE_DEPTH) ? `LC3_PIPE_DEPTH : memCounter;

         env.instMem[instCnt]  = inst.copy();
         instCnt              += 1;
      end else begin
         $fatal(1, "instMem overflown: size: %0d (instCnt: %0x)", env.instMem.size(), instCnt);
         eos(0);
      end
   endfunction

   function void createDataMem( integer dataMemSize, integer defaultVal );
      env.dataMem       = new[ dataMemSize ];
      for( int i = 0; i < dataMemSize; i++ )
         env.dataMem[i] = defaultVal;
   endfunction

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize, string className="Test" );
      this.name        = className;
      this.driverIf    = driverIf;
      this.monIf       = monIf;
      this.ctrlCounter = 0;

      // Create and Connect environment
      env              = new(driverIf, monIf);

      // Create and clear the data mem before program start
      createDataMem(dataMemSize, 0);
   endfunction

   // End of simulation function
   function void eos( bit passReport=1 );
      $display("----------- END OF TEST -------------");
      $display("----------- BEGIN REPORT ------------");
      if( passReport ) begin
         $display("Stats [Driver ]: %0d / %0d Evaluations Failed", env.driver.fail_assert, env.driver.num_assert);
         $display("Stats [Monitor]: %0d / %0d Evaluations Failed", env.monitor.fail_assert, env.monitor.num_assert);
      end

      if( passReport && ((env.driver.fail_assert + env.monitor.fail_assert) == 0) )
         $display("--PASSED--");
      else
         $display("--FAILED--");
   
      $display("------------ END REPORT -------------\n");
      $finish;
   endfunction

   task run();
      // Sequence instructions
      sequenceInstr();
      //displayInstr();

      $display("--------------- Running Test: %s -------------", name);
      env.run();
      eos();
   endtask 

endclass //}
