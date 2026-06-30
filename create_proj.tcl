# Create project
create_project -force mini_sha_pynq_2 D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2 -part xc7z010clg400-1

# Add core files
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_au_unit.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_hash_alu.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_k_rom.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_r_unit.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_controller.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_core.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_datapath.v

# Add AXI wrapper files (from the IP repo since we fixed it there)
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/ip_repo/my_mini_sha_256_pynq_ip_1_0/hdl/my_mini_sha_256_pynq_ip.v
add_files -norecurse D:/Arul/Vivado_Projects_CEERI/ip_repo/my_mini_sha_256_pynq_ip_1_0/hdl/my_mini_sha_256_pynq_ip_slave_lite_v1_0_S00_AXI.v

# Add Testbench
add_files -fileset sim_1 -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/simulation/tb_mini_sha256.v

# Import the files into the project so it owns them (copies them)
import_files -force

# Set top modules
set_property top my_mini_sha_256_pynq_ip [current_fileset]
set_property top tb_mini_sha256 [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project creation complete."
exit
