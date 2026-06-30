open_project D:/Arul/Vivado_Projects_CEERI/mini_sha_pynq_2/mini_sha_pynq_2.xpr

# Remove old files if they exist to avoid conflicts
remove_files [get_files *.v]

# Add all the fixed core files and the new stream wrapper
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_functions.vh
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_au_unit.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_hash_alu.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_k_rom.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_r_unit.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_controller.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_core.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_datapath.v
add_files -norecurse C:/Users/write/.gemini/antigravity/scratch/mini_sha/design/mini_sha256_stream_wrapper.v

# Set top module
set_property top mini_sha256_stream_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Create IP package
ipx::package_project -root_dir D:/Arul/Vivado_Projects_CEERI/ip_repo/mini_sha256_stream_ip -vendor xilinx.com -library user -taxonomy /UserIP
set_property name mini_sha256_stream [ipx::current_core]
set_property display_name {Mini SHA-256 Stream Coprocessor} [ipx::current_core]
set_property description {AXI-Stream wrapper for Mini SHA-256 with hardware padding} [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project
