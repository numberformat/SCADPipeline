#!/usr/bin/env bash
# Copyright (c) 2026 NOAMi (https://noami.us)
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

mkdir -p site
mkdir -p site/images
cp .nojekyll site/

image_size="${OPENSCAD_IMAGE_SIZE:-1200,900}"

append_readme_html() {
  local base_html="$1"
  local out_html="$2"
  local readme_md="README.md"
  local license_txt="LICENSE"
  local build_date
  build_date="$(date +"%B %d, %Y")"
  if [ ! -f "$readme_md" ]; then
    local tmp_readme tmp_license
    tmp_readme="$(mktemp "${TMPDIR:-/tmp}/readme.XXXXXX.html")"
    tmp_license="$(mktemp "${TMPDIR:-/tmp}/license.XXXXXX.html")"
    printf '<section class="readme"><p>README.md file not found at the project root.</p></section>' > "$tmp_readme"
    if [ -f "$license_txt" ]; then
      {
        printf '<section class="license"><pre>'
        sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$license_txt"
        printf '</pre></section>'
      } > "$tmp_license"
    else
      printf '<section class="license"><p>LICENSE file not found at the project root.</p></section>' > "$tmp_license"
    fi
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$base_html" "$out_html" "$tmp_readme" "$tmp_license" "3D Model Viewer" "$build_date" <<'PY'
import sys
from pathlib import Path

base_html = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
out_path = Path(sys.argv[2])
insert = Path(sys.argv[3]).read_text(encoding="utf-8", errors="replace")
license_insert = Path(sys.argv[4]).read_text(encoding="utf-8", errors="replace")
title = sys.argv[5]
build_date = sys.argv[6]

page_title = f'<h1 class="page-title">{title}</h1>'
date_line = f'<div class="build-date">{build_date}</div>'
if "<!--PAGE_TITLE-->" in base_html:
    base_html = base_html.replace("<!--PAGE_TITLE-->", page_title + "\n" + date_line, 1)
if "<!--README-->" in base_html:
    base_html = base_html.replace("<!--README-->", insert, 1)
if "<!--LICENSE-->" in base_html:
    base_html = base_html.replace("<!--LICENSE-->", license_insert, 1)
if "<title>" in base_html:
    import re
    base_html = re.sub(r"<title>[^<]*</title>", f"<title>{title}</title>", base_html, count=1)

out_path.write_text(base_html, encoding="utf-8")
PY
    else
      awk -v insert_file="$tmp_readme" '
        BEGIN {
          while ((getline line < insert_file) > 0) {
            insert = insert line "\n"
          }
          close(insert_file)
        }
        /<!--README-->/ {
          printf "%s", insert
          next
        }
        { print }
      ' "$base_html" > "$out_html"
    fi
    rm -f "$tmp_readme" "$tmp_license"
    return
  fi
  local title
  title="$(sed -n 's/^#[[:space:]]*//p' "$readme_md" | sed -n '1p')"
  if [ -z "$title" ]; then
    title="$(basename "$readme_md" .md)"
  fi
  local tmp_readme tmp_license
  tmp_readme="$(mktemp "${TMPDIR:-/tmp}/readme.XXXXXX.html")"
  tmp_license="$(mktemp "${TMPDIR:-/tmp}/license.XXXXXX.html")"
  if command -v python3 >/dev/null 2>&1; then
    if python3 - <<'PY' >/dev/null 2>&1; then
import markdown
PY
      python3 - "$readme_md" "$tmp_readme" "$license_txt" "$tmp_license" <<'PY'
import sys
from pathlib import Path
import markdown

readme = Path(sys.argv[1])
out_path = Path(sys.argv[2])
license_path = Path(sys.argv[3])
license_out = Path(sys.argv[4])
text = readme.read_text(encoding="utf-8", errors="replace")
html = markdown.markdown(text, extensions=["extra", "tables", "fenced_code"])
readme_section = "<section class=\"readme\">{}</section>".format(html)
out_path.write_text(readme_section, encoding="utf-8")
if license_path.exists():
    lic_text = license_path.read_text(encoding="utf-8", errors="replace")
    lic_html = "<section class=\"license\"><pre>{}</pre></section>".format(
        lic_text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )
else:
    lic_html = "<section class=\"license\"><p>LICENSE file not found at the project root.</p></section>"
license_out.write_text(lic_html, encoding="utf-8")
PY
    elif command -v markdown_py >/dev/null 2>&1; then
      {
        printf '<section class="readme">\n'
        markdown_py -x extra -x tables -x fenced_code "$readme_md"
        printf '\n</section>'
      } > "$tmp_readme"
      if [ -f "$license_txt" ]; then
        {
          printf '<section class="license"><pre>'
          sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$license_txt"
          printf '</pre></section>'
        } > "$tmp_license"
      else
        printf '<section class="license"><p>LICENSE file not found at the project root.</p></section>' > "$tmp_license"
      fi
    else
      echo "WARN: markdown renderer not found. Rebuild the Docker image to include python3-markdown." >&2
      printf '<section class="readme"><pre>' > "$tmp_readme"
      sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$readme_md" >> "$tmp_readme"
      printf '</pre></section>' >> "$tmp_readme"
      if [ -f "$license_txt" ]; then
        {
          printf '<section class="license"><pre>'
          sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$license_txt"
          printf '</pre></section>'
        } > "$tmp_license"
      else
        printf '<section class="license"><p>LICENSE file not found at the project root.</p></section>' > "$tmp_license"
      fi
    fi
  else
    printf '<section class="readme"><pre>' > "$tmp_readme"
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$readme_md" >> "$tmp_readme"
    printf '</pre></section>' >> "$tmp_readme"
    if [ -f "$license_txt" ]; then
      {
        printf '<section class="license"><pre>'
        sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$license_txt"
        printf '</pre></section>'
      } > "$tmp_license"
    else
      printf '<section class="license"><p>LICENSE file not found at the project root.</p></section>' > "$tmp_license"
    fi
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$base_html" "$out_html" "$tmp_readme" "$tmp_license" "$title" "$build_date" <<'PY'
import sys
from pathlib import Path

base_html = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
out_path = Path(sys.argv[2])
insert = Path(sys.argv[3]).read_text(encoding="utf-8", errors="replace")
license_insert = Path(sys.argv[4]).read_text(encoding="utf-8", errors="replace")
title = sys.argv[5]
build_date = sys.argv[6]

page_title = f'<h1 class="page-title">{title}</h1>'
date_line = f'<div class="build-date">{build_date}</div>'
if "<!--PAGE_TITLE-->" in base_html:
    base_html = base_html.replace("<!--PAGE_TITLE-->", page_title + "\n" + date_line, 1)
if "<!--README-->" in base_html:
    base_html = base_html.replace("<!--README-->", insert, 1)
if "<!--LICENSE-->" in base_html:
    base_html = base_html.replace("<!--LICENSE-->", license_insert, 1)
elif "</body>" in base_html:
    base_html = base_html.replace("</body>", insert + "\n</body>", 1)

if "<title>" in base_html:
    import re
    base_html = re.sub(r"<title>[^<]*</title>", f"<title>{title}</title>", base_html, count=1)

out_path.write_text(base_html, encoding="utf-8")
PY
  else
    awk -v insert_file="$tmp_readme" '
      BEGIN {
        while ((getline line < insert_file) > 0) {
          insert = insert line "\n"
        }
        close(insert_file)
      }
      /<!--README-->/ {
        printf "%s", insert
        next
      }
      /<\/body>/ {
        printf "%s", insert
      }
      { print }
    ' "$base_html" > "$out_html"
  fi
  rm -f "$tmp_readme" "$tmp_license"
}

append_readme_html docs/index.html site/index.html

convert_image() {
  local in_path="$1"
  local out_path="$2"
  if command -v magick >/dev/null 2>&1; then
    magick "$in_path" "$out_path"
    return $?
  fi
  if command -v convert >/dev/null 2>&1; then
    convert "$in_path" "$out_path"
    return $?
  fi
  if [ "${in_path##*.}" = "png" ] || [ "${in_path##*.}" = "PNG" ]; then
    cp "$in_path" "$out_path"
    return $?
  fi
  echo "WARN: No image converter found for $in_path (install ImageMagick)" >&2
  return 1
}

render_preview() {
  local stl_path="$1"
  local png_path="$2"
  local stl_dir stl_abs tmp_scad tmp_err
  stl_dir="$(cd "$(dirname "$stl_path")" && pwd)"
  stl_abs="${stl_dir}/$(basename "$stl_path")"
  tmp_scad="$(mktemp "${TMPDIR:-/tmp}/scadpreview.XXXXXX.scad")"
  tmp_err="$(mktemp "${TMPDIR:-/tmp}/scadpreview.XXXXXX.err")"
  printf 'import("%s");\n' "$stl_abs" > "$tmp_scad"
  if ! openscad -o "$png_path" --imgsize="$image_size" --viewall "$tmp_scad" 2>"$tmp_err"; then
    echo "WARN: Failed to render preview for $stl_path" >&2
    if [ -s "$tmp_err" ]; then
      sed -n '1,8p' "$tmp_err" >&2
    fi
  fi
  rm -f "$tmp_scad" "$tmp_err"
}

shopt -s nullglob
scad_files=( src/models/*.scad )
asset_stls=( src/assets/*.stl )
user_images=( src/images/* )
if [ ${#scad_files[@]} -eq 0 ] && [ ${#asset_stls[@]} -eq 0 ]; then
  echo "No .scad files in src/models or .stl files in src/assets." >&2
  exit 1
fi

if [ -d src/assets ]; then
  mkdir -p site/assets
  cp -R src/assets/. site/assets/
fi

printf "[" > site/images.json
images_first=1

if [ -d src/images ] && [ ${#user_images[@]} -gt 0 ]; then
  while IFS= read -r path; do
    [ -f "$path" ] || continue
    base="$(basename "$path")"
    base_no_ext="${base%.*}"
    out="site/images/${base_no_ext}.png"
    if convert_image "$path" "$out"; then
      if [ $images_first -eq 0 ]; then printf "," >> site/images.json; fi
      printf "{\"src\":\"images/%s.png\"}" "$base_no_ext" >> site/images.json
      images_first=0
    fi
  done < <(printf '%s\n' "${user_images[@]}" | sort -f)
fi

printf "[" > site/models.json
first=1
for file in "${scad_files[@]}"; do
  base="$(basename "${file%.scad}")"
  out="site/${base}.stl"
  openscad -o "$out" "$file"
  preview_out="site/images/${base}_stl.png"
  render_preview "$out" "$preview_out"
  if [ -f "$preview_out" ]; then
    if [ $images_first -eq 0 ]; then printf "," >> site/images.json; fi
    printf "{\"src\":\"images/%s_stl.png\",\"stl\":\"%s.stl\"}" "$base" "$base" >> site/images.json
    images_first=0
  fi
  if [ $first -eq 0 ]; then printf "," >> site/models.json; fi
  printf "\"%s.stl\"" "$base" >> site/models.json
  first=0
done
for file in "${asset_stls[@]}"; do
  base="$(basename "$file")"
  base_no_ext="${base%.stl}"
  if [ $first -eq 0 ]; then printf "," >> site/models.json; fi
  printf "\"assets/%s\"" "$base" >> site/models.json
  first=0
  preview_out="site/images/${base_no_ext}_stl.png"
  render_preview "site/assets/$base" "$preview_out"
  if [ -f "$preview_out" ]; then
    if [ $images_first -eq 0 ]; then printf "," >> site/images.json; fi
    printf "{\"src\":\"images/%s_stl.png\",\"stl\":\"assets/%s\"}" "$base_no_ext" "$base" >> site/images.json
    images_first=0
  fi
done
printf "]" >> site/images.json
printf "]" >> site/models.json

echo "Build complete. Output in ./site"
