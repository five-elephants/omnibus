// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Bridge_ram2bus_ro
  ( input logic clk, reset,
    Ram_if.memory ram,
    Bus_if.master bus );

  logic request;
  logic expect_dva;
  logic delay;

  assign request = (ram.en && !ram.we);

  assign bus.MReset_n = ~reset;
  assign bus.MAddr = ram.addr;
  //assign bus.MCmd = request ? Bus::RD : Bus::IDLE;
  assign bus.MRespAccept = 1'b1;
  assign bus.MData = '0;
  assign bus.MByteEn = ram.be;

  assign ram.data_r = bus.SData;
  assign ram.delay = delay;

  always_comb begin
    if( (request && !bus.SCmdAccept) || (expect_dva && (bus.SResp != Bus::DVA)) )
      delay = 1'b1;
    else
      delay = 1'b0;
  end

  always_comb begin
    if( !reset && request )
      bus.MCmd = Bus::RD;
    else
      bus.MCmd = Bus::IDLE;
  end

  always_ff @(posedge clk or posedge reset)
    if( reset )
      expect_dva <= 1'b0;
    else begin
      if( !delay )
        expect_dva <= request;
    end

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
