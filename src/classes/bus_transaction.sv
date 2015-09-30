// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


`ifndef BUS_TRANSACTION_SV_
`define BUS_TRANSACTION_SV_

class Bus_transaction #(type Addr = int, type Data = int);
  localparam int num_data_bytes = $bits(Data)/8;

  typedef logic[num_data_bytes-1:0] Data_byte_en;

  Bus::Ocp_cmd cmd;
  Addr addr;
  Data data;
  Data_byte_en byte_en;

  function new(Bus::Ocp_cmd cmd, Addr addr, Data data, Data_byte_en byte_en = '1);
    this.cmd = cmd;
    this.addr = addr;
    this.data = data;
    this.byte_en = byte_en;
  endfunction

endclass


`endif  /* BUS_TRANSACTION_SV_ */
