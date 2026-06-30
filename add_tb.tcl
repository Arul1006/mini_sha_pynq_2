open_project D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/mini_sha_pynq_2.xpr
add_files -fileset sim_1 -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/tb_mini_sha256_stream.v
set_property top tb_mini_sha256_stream [get_filesets sim_1]
update_compile_order -fileset sim_1
close_project
