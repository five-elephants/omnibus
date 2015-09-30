// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Bus_connect
  ( Bus_if.slave in,
    Bus_if.master out );

  assign
    out.MReset_n = in.MReset_n,
    out.MAddr = in.MAddr,
    out.MCmd = in.MCmd,
    out.MData = in.MData,
    out.MRespAccept = in.MRespAccept,
    out.MByteEn = in.MByteEn;

  assign
    in.SCmdAccept = out.SCmdAccept,
    in.SData = out.SData,
    in.SResp = out.SResp;

endmodule
