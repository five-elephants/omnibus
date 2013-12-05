module Bus_reg_target
  #(parameter int NUM_REGS = 1,
    parameter int ADDR_WIDTH = 32,
    parameter int REG_WIDTH = 32,
    parameter int BASE_ADDR   = 32'h0000_0000,
    parameter int BASE_MASK   = 32'hffff_ffff,
    parameter int OFFSET_MASK = 32'h0000_0001,
    parameter bit[0:NUM_REGS-1] WRITEABLE = '1)
  ( Bus_if.slave bus,
    input logic[REG_WIDTH-1:0] regs_in[0:NUM_REGS-1],
    output logic[REG_WIDTH-1:0] regs[0:NUM_REGS-1] );

  //typedef bus.Addr Addr_t;
  //typedef bus.Data Reg_t;
  typedef logic[ADDR_WIDTH-1:0] Addr_t;
  typedef logic[REG_WIDTH-1:0] Reg_t;

  Addr_t base_masked;
  Addr_t offset_masked;
  Reg_t regs_i[0:NUM_REGS-1];

  assign
    base_masked = bus.MAddr & (BASE_MASK & ~OFFSET_MASK),
    offset_masked = bus.MAddr & OFFSET_MASK;

  // static outputs
  assign bus.SCmdAccept = 1'b1;

  assign regs = regs_i;

  /** Generate enables for read and write accesses */
  always_ff @(posedge bus.Clk or negedge bus.MReset_n)  
    if( !bus.MReset_n ) begin
      bus.SResp <= Bus::NULL;
      bus.SData <= '0;

      for(int i=0; i<NUM_REGS; i++)
        regs_i[i] <= '0;
    end else begin
      // default assignments
      if( bus.MRespAccept ) begin
        bus.SResp <= Bus::NULL;
        bus.SData <= '0;
      end

      if( base_masked == BASE_ADDR ) begin
        if( bus.MCmd == Bus::WR ) begin
          if( WRITEABLE[offset_masked] ) begin
            regs_i[offset_masked] <= bus.MData;
          end

          bus.SResp <= Bus::DVA;
        end

        if( bus.MCmd == Bus::RD ) begin
          bus.SResp <= Bus::DVA;
          bus.SData <= regs_in[offset_masked];
        end
      end
    end

endmodule


// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
