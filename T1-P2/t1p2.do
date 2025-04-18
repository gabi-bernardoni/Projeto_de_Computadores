onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /mips_monocycle_tb/mips_monocycle/rst
add wave -noupdate -format Logic /mips_monocycle_tb/mips_monocycle/lock
add wave -noupdate -format Logic /mips_monocycle_tb/mips_monocycle/clk
add wave -noupdate -divider {Memória de instruções}
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/mips_monocycle/instructionaddress
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/mips_monocycle/instruction
add wave -noupdate -format Literal /mips_monocycle_tb/mips_monocycle/decodedinstruction
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/instruction_memory/memoryarray
add wave -noupdate -divider {ULA}
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/ALUoperand1
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/ALUoperand2
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/result
add wave -noupdate -format Logic /mips_monocycle_tb/MIPS_MONOCYCLE/flagZero
add wave -noupdate -format Logic /mips_monocycle_tb/MIPS_MONOCYCLE/flagNegativo
add wave -noupdate -divider {Registradores}
add wave -noupdate -format Logic /mips_monocycle_tb/MIPS_MONOCYCLE/regWrite
add wave -noupdate -format Literal -radix unsigned /mips_monocycle_tb/MIPS_MONOCYCLE/writeRegister
add wave -noupdate -format Literal -radix hexadecimal -expand /mips_monocycle_tb/mips_monocycle/registerfile
add wave -noupdate -divider {Memória de dados}
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/mips_monocycle/dataaddress
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/mips_monocycle/data_in
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/data_out
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/writeData
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/readData2
add wave -noupdate -format Literal -radix hexadecimal /mips_monocycle_tb/MIPS_MONOCYCLE/dadoSelecionado
add wave -noupdate -format Literal -radix binary /mips_monocycle_tb/MIPS_MONOCYCLE/wbe
add wave -noupdate -format Logic /mips_monocycle_tb/data_memory/ce
add wave -noupdate -format Literal -radix hexadecimal -expand /mips_monocycle_tb/data_memory/memoryarray

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3551 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 66
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ns} {1300 ns}
