module Bus_slave_terminator
  ( Bus_if.slave bus );

  assign 
    bus.SCmdAccept = 1'b0,
    bus.SData = '0,
    bus.SResp = Bus::NULL;

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:
