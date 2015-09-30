// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Bus_reg_target
  #(parameter int NUM_REGS = 1,
    parameter int ADDR_WIDTH = 32,
    parameter int REG_WIDTH = 32,
    parameter int BASE_ADDR   = 32'h0000_0000,
    parameter int BASE_MASK   = 32'hffff_ffff,
    parameter int OFFSET_MASK = 32'h0000_0001,
    parameter bit[0:NUM_REGS-1] WRITEABLE = '1,
    parameter logic[REG_WIDTH-1 : 0] RESET_VALUES[0:NUM_REGS-1] = '{default: '0} )
  ( Bus_if.slave bus,
    input logic[REG_WIDTH-1:0] regs_in[0:NUM_REGS-1],
    output logic[REG_WIDTH-1:0] regs[0:NUM_REGS-1],
    output logic reading[0:NUM_REGS-1],
    output logic writing[0:NUM_REGS-1] );

  //typedef bus.Addr Addr_t;
  //typedef bus.Data Reg_t;
  typedef logic[ADDR_WIDTH-1:0] Addr_t;
  typedef logic[REG_WIDTH-1:0] Reg_t;

  Addr_t base_masked;
  Addr_t offset_masked;
  Reg_t regs_i[0:NUM_REGS-1], next_regs_i[0:NUM_REGS-1];
  Bus::Ocp_resp next_SResp;
  Reg_t next_SData;
  logic next_reading[0:NUM_REGS-1];
  logic next_writing[0:NUM_REGS-1];

  assign
    base_masked = bus.MAddr & (BASE_MASK & ~OFFSET_MASK),
    offset_masked = bus.MAddr & OFFSET_MASK;

  assign regs = regs_i;

  /** Generate enables for read and write accesses */
  always_comb begin
    // default assignments
    next_SResp = bus.SResp;
    next_SData = bus.SData;

    for(int i=0; i<NUM_REGS; i++) begin
      next_reading[i] = 1'b0;
      next_writing[i] = 1'b0;
      next_regs_i[i] = regs_i[i];
    end


    if( bus.MRespAccept ) begin
      next_SResp = Bus::NULL;
      next_SData = '0;
    end

    if( bus.SCmdAccept && (base_masked == BASE_ADDR) ) begin
      if( bus.MCmd == Bus::WR ) begin
        if( WRITEABLE[offset_masked] ) begin
          next_regs_i[offset_masked] = bus.MData;
          next_writing[offset_masked] = 1'b1;
        end

        next_SResp = Bus::DVA;
      end

      if( bus.MCmd == Bus::RD ) begin
        next_SResp = Bus::DVA;
        next_SData = regs_in[offset_masked];
        next_reading[offset_masked] = 1'b1;
      end
    end
  end

  assign
    reading = next_reading,
    writing = next_writing;

  always_comb begin
    if( (bus.SResp != Bus::NULL) && !bus.MRespAccept )
      bus.SCmdAccept = 1'b0;
    else
      bus.SCmdAccept = 1'b1;
  end

  always_ff @(posedge bus.Clk or negedge bus.MReset_n)
    if( !bus.MReset_n ) begin
      bus.SResp <= Bus::NULL;
      bus.SData <= '0;

      for(int i=0; i<NUM_REGS; i++)
        regs_i[i] <= RESET_VALUES[i];
    end else begin
      bus.SResp <= next_SResp;
      bus.SData <= next_SData;
      regs_i <= next_regs_i;
    end


endmodule


// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
