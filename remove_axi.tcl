open_project D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/mini_sha_pynq_2.xpr
remove_files [get_files my_mini_sha_256_pynq_ip.v]
remove_files [get_files my_mini_sha_256_pynq_ip_slave_lite_v1_0_S00_AXI.v]
set_property top mini_sha256_core [current_fileset]
update_compile_order -fileset sources_1
puts "Successfully removed AXI wrappers."
exit
