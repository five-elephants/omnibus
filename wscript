
def configure(conf):
    conf.env.OMNIBUS_PACKAGES = [
        conf.path.abspath() + '/src/packages/bus_pkg.sv',
    ]
    conf.env.OMNIBUS_INTERFACES = [
        conf.path.abspath() + '/src/interfaces/bus_if.sv',
        conf.path.abspath() + '/src/interfaces/ram_if.sv',
    ]
    conf.env.OMNIBUS_MODULES = [
        conf.path.abspath() + '/src/modules/bridge_bus2ram.sv',
        conf.path.abspath() + '/src/modules/bridge_ram2bus_ro.sv',
        conf.path.abspath() + '/src/modules/bus_delay.sv',
        conf.path.abspath() + '/src/modules/bus_if_arb.sv',
        conf.path.abspath() + '/src/modules/bus_if_split.sv',
        conf.path.abspath() + '/src/modules/bus_master_terminator.sv',
        conf.path.abspath() + '/src/modules/bus_reg_target.sv',
        conf.path.abspath() + '/src/modules/bus_serial.sv',
        conf.path.abspath() + '/src/modules/bus_slave_terminator.sv',
    ]
    conf.env.OMNIBUS_SIM_PACKAGES = [
        conf.path.abspath() + '/src/classes/bus_tb_pkg.sv',
    ]
    conf.env.OMNIBUS_VERILOG_INCLUDE = [
        conf.path.abspath() + '/src/classes',
    ]

    conf.env.OMNIBUS_M4_INCLUDE = [
        conf.path.abspath() + '/m4',
    ]

