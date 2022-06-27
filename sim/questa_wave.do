onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group agent_in /amiq_fifo_tb_top/out_if/clock
add wave -noupdate -expand -group agent_in /amiq_fifo_tb_top/out_if/reset_n
add wave -noupdate -expand -group agent_in /amiq_fifo_tb_top/out_if/data
add wave -noupdate -expand -group agent_in /amiq_fifo_tb_top/out_if/address
add wave -noupdate -expand -group agent_out /amiq_fifo_tb_top/in_if/clock
add wave -noupdate -expand -group agent_out /amiq_fifo_tb_top/in_if/reset_n
add wave -noupdate -expand -group agent_out /amiq_fifo_tb_top/in_if/data
add wave -noupdate -expand -group agent_out /amiq_fifo_tb_top/in_if/address
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {68 ns}
