// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


/** OMNIBUS valve
 * If close is asserted, in and out are disconnected from each other.
   * This means, that requests on in and responses on out are still
   * accepted, but not forwarded to the other side. */ 
module Bus_valve
  ( Bus_if.slave in,
    Bus_if.master out,
    input logic close,
    input logic reset );

  always_comb begin 
    if( close ) begin
      out.MReset_n = ~reset;
      out.MAddr = 'x;
      out.MCmd = Bus::IDLE;
      out.MData = 'x;
      out.MRespAccept = 1'b1;
      out.MByteEn = 'x;

      in.SCmdAccept = 1'b1;
      in.SData = 'x;
      in.SResp = Bus::NULL;
    end else begin
      out.MReset_n = in.MReset_n;
      out.MAddr = in.MAddr;
      out.MCmd = in.MCmd;
      out.MData = in.MData;
      out.MRespAccept = in.MRespAccept;
      out.MByteEn = in.MByteEn;

      in.SCmdAccept = out.SCmdAccept;
      in.SData = out.SData;
      in.SResp = out.SResp;
    end
  end

endmodule

/* vim: set et fenc= ff=unix sts=2 sw=2 ts=2 : */
