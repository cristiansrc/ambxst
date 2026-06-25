import sys, os, subprocess
from pathlib import Path

wallpaper = sys.argv[1]       # image path
scheme = sys.argv[2]          # e.g. scheme-content
screen = sys.argv[3]          # e.g. HDMI-A-1
config_path = sys.argv[4]     # original config.toml
light = len(sys.argv) > 5 and sys.argv[5] == "light"

home = str(Path.home())
colors_dir = f"{home}/.cache/ambxst"
orig = Path(config_path)
tmp = orig.parent / f"config_{screen}.toml"

# Only modify output_path, keep input_path as-is
text = orig.read_text()
text = text.replace(
    'output_path = "~/.cache/ambxst/colors.json"',
    f'output_path = "{colors_dir}/colors_{screen}.json"'
)
tmp.write_text(text)

# Run matugen
args = ["matugen", "image", wallpaper, "--source-color-index", "0", "-c", str(tmp), "-t", scheme]
if light:
    args.extend(["-m", "light"])

r = subprocess.run(args, capture_output=True, text=True)
tmp.unlink(missing_ok=True)
if r.returncode != 0:
    sys.stderr.write(r.stderr)
    sys.exit(r.returncode)
print(f"OK {colors_dir}/colors_{screen}.json")
