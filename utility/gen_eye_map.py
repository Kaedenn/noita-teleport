import numpy as np
import cv2
from os import path
import xml.etree.ElementTree as ET
import re

# Change this!
DATAPATH = "path/to/noita/data"

BIOME_MAP = cv2.imread(path.join(DATAPATH, "biome_impl/biome_map.png"))
BIOMES_ALL = ET.parse(path.join(DATAPATH, "biome/_biomes_all.xml"))

BIOME_COLORS = {}
for child in BIOMES_ALL.getroot():
  color = child.attrib['color']
  fn = child.attrib['biome_filename'][5:]
  BIOME_COLORS[color[2:]] = fn

BGPATT = re.compile(r'\sbackground_image="([^"]*)"')
def get_biome_bg(fn):
  fn = path.join(DATAPATH, fn)
  with open(fn, "rt") as src:
    data = src.read()
  matches = BGPATT.findall(data)
  if len(matches) == 0:
    print(fn, "has no background!")
    return "NULL"
  elif len(matches) > 1:
    print(fn, "Multiple bgs?", matches)
  return matches[0]

BIOME_COLOR_BGS = {}
for (color, fn) in BIOME_COLORS.items():
  BIOME_COLOR_BGS[color.lower()] = get_biome_bg(fn)

def to_hex_color(v):
  val = (v[2] << 16) | (v[1] << 8) | (v[0])
  return "{:06x}".format(val)

MAPW = BIOME_MAP.shape[1]
MAPH = BIOME_MAP.shape[0]
valid_spawn_locs = np.zeros((MAPH, MAPW))
for row in range(MAPH):
  for col in range(MAPW):
    hexcolor = to_hex_color(BIOME_MAP[row, col, :])
    if not hexcolor in BIOME_COLOR_BGS:
      print("Missing color:", hexcolor)
      continue
    bgname = BIOME_COLOR_BGS[hexcolor]
    if bgname == 'data/weather_gfx/background_cave_02.png':
      valid_spawn_locs[row, col] = True

spawn_locs_image = valid_spawn_locs.astype(np.uint8)*255
spawn_locs_image = np.dstack([spawn_locs_image]*3)
side_by_side = np.hstack([BIOME_MAP, spawn_locs_image])
cv2.imwrite("eye_spawn_locations.png", side_by_side)
