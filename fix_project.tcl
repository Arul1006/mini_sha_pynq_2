remove_files -quiet [get_files -quiet -filter {NAME =~ *scratch*}]
add_files -norecurse {
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_au_unit.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_hash_alu.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_k_rom.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_r_unit.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_controller.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_core.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_datapath.v
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_functions.vh
    D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_stream_wrapper.v
}
set_property top tb_mini_sha256_stream [get_filesets sim_1]
update_compile_order -fileset sources_1
