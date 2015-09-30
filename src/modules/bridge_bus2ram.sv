// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


import Bus::*;

module Bridge_bus2ram
  #(parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32 )
  ( Bus_if.slave bus_if,
    Ram_if.client ram_if );

  //---------------------------------------------------------------------------
  // Local types & signals
  //---------------------------------------------------------------------------
 
  localparam int NUM_BYTES = DATA_WIDTH/8;

  typedef enum logic[3:0] {
    S_IDLE             = 4'b0001,
    S_RESPONDING       = 4'b0010,
    S_RESP_PENDING     = 4'b0100,
    S_REQ_RESP_PENDING = 4'b1000,
    S_UNDEF            = 4'bxxxx
  } State;

  typedef struct packed {
    Bus::Ocp_cmd MCmd;
    logic[ADDR_WIDTH-1:0] MAddr;
    logic[DATA_WIDTH-1:0] MData;
    //logic[(bus_if.data_width/8)-1:0] MByteEn;
    logic[NUM_BYTES-1:0] MByteEn;
  } Request;

  State state;
  logic[DATA_WIDTH-1:0] read_reg;
  logic read_reg_en;  
  Request req_reg;
  logic req_reg_en;

  //---------------------------------------------------------------------------
  // control statemachine
  //---------------------------------------------------------------------------
  
  always_ff @(posedge bus_if.Clk or negedge bus_if.MReset_n)
    if( !bus_if.MReset_n )
      state <= S_IDLE;
    else
      unique case(state)
        S_IDLE: begin
          if( bus_if.MCmd == Bus::RD || bus_if.MCmd == Bus::WR )
            state <= S_RESPONDING;
        end

        S_RESPONDING: begin
          if( !bus_if.MRespAccept && (bus_if.MCmd == Bus::IDLE) )
            state <= S_RESP_PENDING;
          else if( !bus_if.MRespAccept 
              && ((bus_if.MCmd == Bus::RD) || (bus_if.MCmd == Bus::WR)) )
            state <= S_REQ_RESP_PENDING;
          else if( bus_if.MCmd == Bus::IDLE )
            state <= S_IDLE;
        end

        S_RESP_PENDING: begin
          if( bus_if.MRespAccept )
            state <= S_IDLE;
        end

        S_REQ_RESP_PENDING: begin
          if( bus_if.MRespAccept )
           state <= S_RESPONDING; 
        end

        default: begin
          state <= S_UNDEF;
        end
      endcase

  always_comb begin
    // default assignment
    bus_if.SResp = Bus::NULL;
    bus_if.SCmdAccept = 1'b1;
    bus_if.SData = ram_if.data_r;
    read_reg_en = 1'b0;
    req_reg_en = 1'b0;
    ram_if.addr = bus_if.MAddr;
    ram_if.en = (bus_if.MCmd == Bus::RD || bus_if.MCmd == Bus::WR);
    ram_if.we = (bus_if.MCmd == Bus::WR);
    ram_if.be = bus_if.MByteEn;
    ram_if.data_w = bus_if.MData;

    unique case(state)
      S_IDLE: begin
      end

      S_RESPONDING: begin
        bus_if.SResp = Bus::DVA;
        read_reg_en = 1'b1;
        req_reg_en = 1'b1;
      end

      S_RESP_PENDING: begin
        bus_if.SResp = Bus::DVA;
        bus_if.SCmdAccept = 1'b0;
        bus_if.SData = read_reg;
      end

      S_REQ_RESP_PENDING: begin
        bus_if.SResp = Bus::DVA;
        bus_if.SCmdAccept = 1'b0;
        bus_if.SData = read_reg;
        ram_if.addr = req_reg.MAddr;
        ram_if.en = (req_reg.MCmd == Bus::RD || bus_if.MCmd == Bus::WR);
        ram_if.we = (req_reg.MCmd == Bus::WR);
        ram_if.be = req_reg.MByteEn;
        ram_if.data_w = req_reg.MData;
      end

      default: begin
        bus_if.SResp = Bus::Ocp_resp'('x);
        bus_if.SCmdAccept = 1'bx;
        bus_if.SData = 'x;
        read_reg_en = 1'bx;
        req_reg_en = 1'bx;
        ram_if.addr = 'x;
        ram_if.en = 1'bx;
        ram_if.we = 1'bx;
        ram_if.be = 'x;
        ram_if.data_w = 'x;
      end
    endcase
  end


  //---------------------------------------------------------------------------
  // datapath
  //---------------------------------------------------------------------------

  always_ff @(posedge bus_if.Clk or negedge bus_if.MReset_n)
    if( !bus_if.MReset_n )
      read_reg <= '0;
    else
      if( read_reg_en )
        read_reg <= ram_if.data_r;

  always_ff @(posedge bus_if.Clk or negedge bus_if.MReset_n)
    if( !bus_if.MReset_n )
      req_reg <= '0;
    else
      if( req_reg_en ) begin
        req_reg.MCmd <= bus_if.MCmd;
        req_reg.MData <= bus_if.MData;
        req_reg.MAddr <= bus_if.MAddr;
        req_reg.MByteEn <= bus_if.MByteEn;
      end
        

  //---------------------------------------------------------------------------
  // Assertions
  //---------------------------------------------------------------------------
  
  `ifndef SYNTHESIS
    check_ram_no_delay: assert property (
      @(posedge bus_if.Clk) disable iff(!bus_if.MReset_n)
      ( ram_if.delay == 1'b0 )
    ) else
      $error("Bridge_bus2ram does not support the delay signal of Ram_if");
  `endif /** SYNTHESIS */
  

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
