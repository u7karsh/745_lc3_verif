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
      integer numTrans             = 8 + 100;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];
      for( int i = 0; i < 8; i++ ) begin
         instMemEntry.create(AND, 7-i, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end
      for( int i = 0; i < numTrans - 8; i++ ) begin
         // Basic instructions
         opcode_t opList[]  = {ADD, /*BR,*/ AND, NOT/*, LD, LDR, LDI, LEA, ST, STI, STR*/};

         if( instMemEntry.randomize() with { opcode inside {opList}; } ) begin
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
      string stage;
      integer mon_num_assert = 0, mon_fail_assert = 0;
      integer dri_num_assert = 0, dri_fail_assert = 0;
      $display("----------- END OF TEST -------------");
      $display("----------- BEGIN REPORT ------------");
      if( passReport ) begin
         $display("Stats [Driver ]: ");
         if( env.driver.num_assert.first(stage) ) begin
            do begin
               dri_num_assert    += env.driver.num_assert[stage];
               dri_fail_assert   += env.driver.fail_assert[stage];
               $display("      [%s\t]\t%0d / %0d Evaluations Failed", stage, env.driver.fail_assert[stage], env.driver.num_assert[stage]);
            end
            while( env.driver.num_assert.next(stage) );
         end
         $display("---------------");
         $display("      [TOTAL\t]\t%0d / %0d Evaluations Failed", dri_fail_assert, dri_num_assert);

         $display("\nStats [Monitor]: ");
         if( env.monitor.num_assert.first(stage) ) begin
            do begin
               mon_num_assert    += env.monitor.num_assert[stage];
               mon_fail_assert   += env.monitor.fail_assert[stage];
               $display("      [%s\t]\t%0d / %0d Evaluations Failed", stage, env.monitor.fail_assert[stage], env.monitor.num_assert[stage]);
            end
            while( env.monitor.num_assert.next(stage) );
         end 
         $display("---------------");
         $display("      [TOTAL\t]\t%0d / %0d Evaluations Failed", mon_fail_assert, mon_num_assert);
      end

      if( passReport && ((mon_fail_assert + dri_fail_assert) == 0) )
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
