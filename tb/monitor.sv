module Monitor( Lc3_mon_if mif );

wire clk;
assign clk            = mif.clk;

Instruction instMem[];

// Monitor - fetch
initial begin
   `ifdef DEBUG
      $monitor("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", $time, monif.FETCH.pc, monif.FETCH.npc, monif.FETCH.instrmem_rd);
   `endif
end

endmodule
