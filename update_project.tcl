open_project D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/mini_sha_pynq_2.xpr

# Remove old files if they exist to avoid conflicts
remove_files [get_files *.v]

# Add all the fixed core files and the new stream wrapper from the local src folder
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_functions.vh
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_au_unit.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_hash_alu.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_k_rom.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_r_unit.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_controller.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_core.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_datapath.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/src/mini_sha256_stream_wrapper.v

# Set top module
set_property top mini_sha256_stream_wrapper [current_fileset]
update_compile_order -fileset sources_1
close_project
