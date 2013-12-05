module Bus_master_terminator
  ( Bus_if.master bus );

  assign
    bus.MReset_n = 1'b1,
    bus.MCmd = Bus::IDLE,
    bus.MDataValid = 1'b0,
    bus.MByteEn = '0;
    bus.MData = '0,
    bus.MAddr = '0,
    bus.MRespAccept = 1'b0;


endmodule


// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
