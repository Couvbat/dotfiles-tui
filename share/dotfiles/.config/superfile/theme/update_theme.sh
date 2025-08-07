#!/bin/bash

# Import pywal colors
source "${HOME}/.cache/wal/colors.sh"

# Define function to convert RGB to hex
rgb_to_hex() {
  printf "#%02x%02x%02x" $1 $2 $3
}

# Create the custom.toml file
cat > "${HOME}/.config/superfile/theme/custom.toml" << EOF
# Auto-generated Superfile theme based on pywal colors
# Last updated: $(date)

# ========= Border =========
file_panel_border = "${color5}"
sidebar_border = "${color4}"
footer_border = "${color4}"

# ========= Border Active =========
file_panel_border_active = "${color6}"
sidebar_border_active = "${color6}"
footer_border_active = "${color6}"
modal_border_active = "${color6}"

# ========= Background (bg) =========
full_screen_bg = "${color0}"
file_panel_bg = "${color0}"
sidebar_bg = "${color0}"
footer_bg = "${color0}"
modal_bg = "${color0}"

# ========= Foreground (fg) =========
full_screen_fg = "${color1}"
file_panel_fg = "${color1}"
sidebar_fg = "${color1}"
footer_fg = "${color1}"
modal_fg = "${color1}"

# ========= Special Color =========
cursor = "${color15}"
correct = "${color2}"
error = "${color1}"
hint = "${color6}"
cancel = "${color5}"
# Gradient color can only have two color!
gradient_color = ["${color4}", "${color5}"]

# ========= File Panel Special Items =========
file_panel_top_directory_icon = "${color2}"
file_panel_top_path = "${color4}"
file_panel_item_selected_fg = "${color6}"
file_panel_item_selected_bg = "${color0}"

# ========= Sidebar Special Items =========
sidebar_title = "${color6}"
sidebar_item_selected_fg = "${color6}"
sidebar_item_selected_bg = "${color0}"
sidebar_divider = "${color8}"

# ========= Modal Special Items =========
modal_cancel_fg = "${color0}"
modal_cancel_bg = "${color5}"

modal_confirm_fg = "${color0}"
modal_confirm_bg = "${color6}"

# ========= Help Menu =========
help_menu_hotkey = "${color6}"
help_menu_title = "${color5}"
EOF

echo "Superfile theme updated with pywal colors"