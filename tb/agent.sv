// Class for common functionality between monitor and driver
class Agent;
   integer num_assert[ string ];
   integer fail_assert[ string ];

   virtual function void printInstMemIndex( integer index );
      check("AGENT", FATAL, index >= 0 && index < top.test.env.instMem.size(), 
         $psprintf("[printInstMemIndex] Out of bounds instruct memory access at %0d", index));
      top.test.env.instMem[index].print();
   endfunction

   virtual function Instruction getInstIndex( integer index, bit safe=0 );
      bit cond = index >= 0 && index < top.test.env.instMem.size();
      if( !safe )
         check("AGENT", FATAL, cond, 
            $psprintf("[getInstIndex] Out of bounds instruct memory access at %0d", index));

      // Stick to last value for out of bounds access
      index = cond ? index : top.test.env.instMem.size() - 1;

      return top.test.env.instMem[index];
   endfunction

   virtual function integer getInstMemSize();
      return top.test.env.instMem.size();
   endfunction

   // Read data memory
   virtual function data_t readDataMem( integer address );
      check("AGENT", FATAL, address < top.test.env.dataMem.size(), $psprintf("Out of bounds memory access %0x", address));
      return top.test.env.dataMem[ address ];
   endfunction

   // write data memory
   virtual function void writeDataMem( integer address, data_t value );
      check("AGENT", FATAL, address < top.test.env.dataMem.size(), $psprintf("Out of bounds memory access %0x", address));
      top.test.env.dataMem[ address ] = value;
   endfunction

   // assert 
   virtual function void check(string stage, severityT severity, reg cond, string A);
      if( !num_assert.exists(stage) ) begin
         num_assert [stage]    = 0;
         fail_assert[stage]    = 0;
      end

      num_assert[stage]       += 1;
      if(!cond) begin
         fail_assert[stage]   += 1;
         if( severity == FATAL ) begin
            $error(1, "\n%t [CHECKER.%s] %s", $time, stage, A);
            void'(top.test.eos());
         end
         else
            $warning("\n%t [CHECKER.%s] %s", $time, stage, A);
      end
   endfunction

   function new();
   endfunction

endclass
