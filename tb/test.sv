class Test; //{
   // Interfaces
   virtual Lc3_dr_if  driverIf;
   virtual Lc3_mon_if monIf;
   Env                env;

   // Populates env's instruct mem
   // TODO: Do a reg/memory warmup to remove
   // don't cares
   function void genAsm( integer numTrans );
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];
      for( int i = 0; i < numTrans; i++ ) begin
         if( instMemEntry.randomize() with { opcode inside {ADD, /*BR,*/ AND, NOT/*, LD, LDR, LDI, LEA, ST, STI, STR*/}; } ) begin
            env.instMem[i]         = instMemEntry.copy();
         end else begin
            $error("Failed to randomize instMemEntry");
         end
      end
   endfunction

   function void createDataMem( integer dataMemSize, integer defaultVal );
      env.dataMem       = new[ dataMemSize ];
      for( int i = 0; i < dataMemSize; i++ )
         env.dataMem[i] = defaultVal;
   endfunction

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer asmTrans, integer dataMemSize );
      this.driverIf = driverIf;
      this.monIf    = monIf;

      // Create and Connect environment
      env           = new(driverIf, monIf);

      // Generate random asm
      genAsm( asmTrans );

      // Create and clear the data mem before program start
      createDataMem(dataMemSize, 0);
   endfunction

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
      env.run();
      eos();
   endtask 

endclass //}
