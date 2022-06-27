# Defines
// input width (in bits)
+define+N=8
// output width (in bits)
+define+M=8
// threshold width (in bits)
+define+P=3

# Specify directories to search for include files
+incdir+$PROJ_HOME/tb/sv
+incdir+$PROJ_HOME/tb/top
+incdir+$PROJ_HOME/tb/tests
+incdir+$PROJ_HOME/rtl
+incdir+$PROJ_HOME/tb/sv/env/
+incdir+$PROJ_HOME/tb/sv/write_agent
+incdir+$PROJ_HOME/tb/sv/read_agent

# pay attention to include order

# Include interfaces files
$PROJ_HOME/tb/sv/read_agent/amiq_fifo_read_if.sv
$PROJ_HOME/tb/sv/write_agent/amiq_fifo_write_if.sv
$PROJ_HOME/tb/sv/env/amiq_fifo_control_if.sv
$PROJ_HOME/tb/sv/env/amiq_fifo_status_if.sv
$PROJ_HOME/tb/sv/env/amiq_fifo_block_if.sv

# Include additional package files here 
$PROJ_HOME/tb/sv/write_agent/amiq_fifo_write_agent_pkg.sv
$PROJ_HOME/tb/sv/read_agent/amiq_fifo_read_agent_pkg.sv
$PROJ_HOME/tb/sv/env/amiq_fifo_env_pkg.sv
$PROJ_HOME/tb/tests/amiq_fifo_test_pkg.sv

# Include RTL files 
#TODO comment these here if .v or .sv files dont exist
#$PROJ_HOME/rtl/*.v
$PROJ_HOME/rtl/amiq_fifo_rtl.sv

# Include top file
$PROJ_HOME/tb/top/amiq_fifo_tb_top.sv
