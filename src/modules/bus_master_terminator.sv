// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


module Bus_master_terminator
  ( Bus_if.master bus );

  assign
    bus.MReset_n = 1'b1,
    bus.MCmd = Bus::IDLE,
    bus.MByteEn = '0,
    bus.MData = '0,
    bus.MAddr = '0,
    bus.MRespAccept = 1'b0;


endmodule


// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
