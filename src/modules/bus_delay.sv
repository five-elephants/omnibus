// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Bus_delay
  #(parameter int addr_width = 32,
    parameter int data_width = 32)
  ( Bus_if.slave in,
    Bus_if.master out );

  assign out.MReset_n = in.MReset_n;

  // XXX parameters!!!
  typedef logic[data_width-1:0] Data;
  typedef logic[addr_width-1:0] Addr;
  typedef logic[data_width/8-1:0] Byte_en;

  typedef struct packed {
    Bus::Ocp_cmd MCmd;
    Data MData;
    Addr MAddr;
    Byte_en MByteEn;
  } Request;

  typedef struct packed {
    Bus::Ocp_resp SResp;
    Data SData;
  } Response;
 
  logic req_in, req_out;
  logic req_accept_in;
  Request req_data_in, req_data_out;
  Response resp_data_in, resp_data_out;
  logic resp_in;
  logic resp_out;

  //---------------------------------------------------------------------------
  // Request direction
  //---------------------------------------------------------------------------
 
  assign
    req_data_in.MCmd = in.MCmd,
    req_data_in.MData = in.MData,
    req_data_in.MAddr = in.MAddr,
    req_data_in.MByteEn = in.MByteEn;

  Delay_stage #(.WIDTH($bits(Request))) req_stage (
    .clk(in.Clk),
    .reset(~in.MReset_n),
    .req_in(req_in),
    .accept_in(req_accept_in),
    .req_out(req_out),
    .accept_out(out.SCmdAccept),
    .data_in(req_data_in),
    .data_out(req_data_out)
  );

  assign 
    in.SCmdAccept = req_accept_in;

  assign req_in = (in.MCmd != Bus::IDLE);
  assign out.MCmd = req_out ? req_data_out.MCmd : Bus::IDLE;
  assign 
    out.MData = req_data_out.MData,
    out.MAddr = req_data_out.MAddr,
    out.MByteEn = req_data_out.MByteEn;

  //---------------------------------------------------------------------------
  // Response direction
  //---------------------------------------------------------------------------
 
  assign
    resp_data_in.SResp = out.SResp,
    resp_data_in.SData = out.SData;

  Delay_stage #(.WIDTH($bits(Response))) resp_stage (
    .clk(in.Clk),
    .reset(~in.MReset_n),
    .req_in(resp_in),
    .accept_in(out.MRespAccept),
    .req_out(resp_out),
    .accept_out(in.MRespAccept),
    .data_in(resp_data_in),
    .data_out(resp_data_out)
  );

  assign resp_in = (out.SResp != Bus::NULL);
  assign in.SResp = resp_out ? resp_data_out.SResp : Bus::NULL;
  assign in.SData = resp_data_out.SData;

endmodule


module Delay_stage
  #(parameter int WIDTH = 1)
  ( input logic clk, reset,
    input logic req_in,
    output logic accept_in,
    output logic req_out,
    input logic accept_out,
    input logic[WIDTH-1:0] data_in,
    output logic[WIDTH-1:0] data_out );

  typedef enum logic[2:0] {
    S_0 = 3'b001,
    S_1 = 3'b010,
    S_2 = 3'b100,
    S_UNDEF = 3'bxxx
  } State;

  typedef logic[WIDTH-1:0] Data;

  State state;
  logic push, pop;
  logic cur_in, cur_out;
  Data r[0:1];
  logic accept_in_i;
  logic req_out_i;

  //---------------------------------------------------------------------------
  // Datapath
  //---------------------------------------------------------------------------
  
  assign accept_in = accept_in_i;
  assign req_out = req_out_i;
  assign push = req_in & accept_in_i;
  assign pop = req_out_i & accept_out;

  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      cur_in <= 1'b0;
      cur_out <= 1'b0;
      r[0] <= '0;
      r[1] <= '0;
    end else begin
      if( push ) begin
        cur_in <= ~cur_in;

        unique case(cur_in)
          1'b0: r[0] <= data_in;
          1'b1: r[1] <= data_in;
          default: begin
            r[0] <= 'x;
            r[1] <= 'x;
          end
        endcase
      end

      if( pop )
        cur_out <= ~cur_out;
    end
 
  always_comb 
    unique case(cur_out)
      1'b0: data_out = r[0];
      1'b1: data_out = r[1];
      default: data_out = 'x;
    endcase


  //---------------------------------------------------------------------------
  // State machine
  //---------------------------------------------------------------------------
  
  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      state <= S_0;
    end else
      unique case(state)
        S_0: begin
          if( push )
            state <= S_1;
        end

        S_1: begin
          if( push && !pop )
            state <= S_2;
          else if( push && pop )
            state <= S_1;
          else if( !push && pop )
            state <= S_0;
        end

        S_2: begin
          if( pop )
            state <= S_1;
        end

        default:
          state <= S_UNDEF;
      endcase

    always_comb begin
      // default assignment
      req_out_i = 1'b0;
      accept_in_i = 1'b0;

      unique case(state)
        S_0: begin
          accept_in_i = 1'b1;
        end

        S_1: begin
          req_out_i = 1'b1;
          accept_in_i = 1'b1;
        end

        S_2: begin
          req_out_i = 1'b1;
          accept_in_i = 1'b0;
        end

        default: begin
          req_out_i = 1'bx;
          accept_in_i = 1'bx;
        end
      endcase
    end

  //---------------------------------------------------------------------------
  // Assertions
  //---------------------------------------------------------------------------
 
  `ifndef SYNTHESIS
    check_no_push_while_full: assert property(
      @(posedge clk) disable iff(reset)
      ( push |-> ((state == S_0) || (state == S_1)) )
    ) else
      $error("push while full");

    check_no_pop_while_empty: assert property(
      @(posedge clk) disable iff(reset)
      ( pop |-> ((state == S_1) || (state == S_2)) )
    ) else
      $error("pop while empty");
  `endif /** SYNTHESIS */
  

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
