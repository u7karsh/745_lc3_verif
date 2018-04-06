class Test; //{
   // Interfaces
   virtual Lc3_dr_if  driverIf;
   virtual Lc3_mon_if monIf;
   Env                env;
   integer            instCnt = 0;
   string             name;

   // Populates env's instruct mem
   // This is the base function that will be overridden in
   // all tests. It doesn't have LD/SD and BR as mem warmup
   // is not done
   virtual function void sequenceInstr();
      integer numTrans             = 10;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];
      for( int i = 0; i < numTrans; i++ ) begin
         if( instMemEntry.randomize() with { opcode inside {ADD, /*BR,*/ AND, NOT/*, LD, LDR, LDI, LEA, ST, STI, STR*/}; } ) begin
            pushInst(instMemEntry);
         end else begin
            $fatal(1, "Failed to randomize instMemEntry");
         end
      end
   endfunction

   function void pushInst( Instruction inst );
      if( instCnt < env.instMem.size() ) begin
         env.instMem[instCnt]  = inst.copy();
         instCnt              += 1;
      end else begin
         $fatal(1, "instMem overflown: size: %0d (instCnt: %0x)", env.instMem.size(), instCnt);
      end
   endfunction

   function void createDataMem( integer dataMemSize, integer defaultVal );
      env.dataMem       = new[ dataMemSize ];
      for( int i = 0; i < dataMemSize; i++ )
         env.dataMem[i] = defaultVal;
   endfunction

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize, string className="Test" );
      this.name     = className;
      this.driverIf = driverIf;
      this.monIf    = monIf;

      // Create and Connect environment
      env           = new(driverIf, monIf);

      // Create and clear the data mem before program start
      createDataMem(dataMemSize, 0);
   endfunction

   // End of simulation function
   function void eos();
      $display("----------- END OF TEST -------------");
      $display("----------- BEGIN REPORT ------------");
      $display("Stats [Driver ]: %0d / %0d Evaluations Failed", env.driver.fail_assert, env.driver.num_assert);
      $display("Stats [Monotor]: %0d / %0d Evaluations Failed", env.monitor.fail_assert, env.monitor.num_assert);
      if( (env.driver.fail_assert + env.monitor.fail_assert) == 0 )
         $display("ALL TEST CASES PASSED!!!!!");
      else
         $display("YO DAWG! YOU GOT SOME FAILED TEST CASES. SORRY BRUH!");
   
      $display("------------ END REPORT -------------\n");
   endfunction

   task run();
      // Sequence instructions
      sequenceInstr();

      $display("--------------- Running Test: %s -------------", name);
      env.run();
      eos();
   endtask 

endclass //}
