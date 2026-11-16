#!/usr/bin/python3
#
# SkillLevelsConverter2.py
#
# Converts SkillLineAbility.<build>.csv and SpellName.<build>.csv from wago.tools
# into Lua tables for CraftForge (Data/SkillLevelData*.lua).
#

import csv
import os
import re
import sys


def spells_list_read(file_name):
	spell_to_skill_line = {}
	min_skill_line_rank = {}
	trivial_low = {}
	trivial_high = {}
	spell_to_name = {}

	with open(file_name, newline='', encoding='utf-8') as f:
		for row in csv.DictReader(f, delimiter=','):
			low = int(row['TrivialSkillLineRankLow'])
			high = int(row['TrivialSkillLineRankHigh'])
			if low + high > 0:
				spell_id = int(row['Spell'])
				spell_to_skill_line[spell_id] = int(row['SkillLine'])
				min_skill_line_rank[spell_id] = int(row['MinSkillLineRank'])
				trivial_low[spell_id] = low
				trivial_high[spell_id] = high

	spellname_file = file_name.replace("SkillLineAbility", "SpellName")
	with open(spellname_file, newline='', encoding='utf-8') as f:
		for row in csv.DictReader(f, delimiter=','):
			spell_to_name[int(row['ID'])] = row['Name_lang']

	return spell_to_skill_line, min_skill_line_rank, trivial_low, trivial_high, spell_to_name


def spells_list_str(spell_id, min_rank, trivial_low, trivial_high, spell_to_name):
	mid = int((trivial_low[spell_id] + trivial_high[spell_id]) / 2)
	line = f"[{spell_id}] = '{min_rank[spell_id]}/{trivial_low[spell_id]}/{mid}/{trivial_high[spell_id]}'"
	if spell_id in spell_to_name:
		clean_name = re.sub(r' \|A:.*\|a', '', str(spell_to_name[spell_id]))
		line += f",    -- {clean_name}\n"
	else:
		line += ",\n"
	return line


def spells_list_write(file_name, data):
	spell_to_skill_line, min_rank, trivial_low, trivial_high, spell_to_name = data
	output_file = os.path.splitext(file_name)[0] + '.lua'
	basename = os.path.basename(output_file)
	filename = basename.split('.', 1)[0]

	spell_name_output = output_file.replace("SkillLineAbility", "SpellName")
	basename2 = os.path.basename(spell_name_output)

	with open(output_file, 'w', encoding='utf-8', newline='\n') as o, \
		open(spell_name_output, 'w', encoding='utf-8', newline='\n') as n:
		o.write(f"-- {basename}\n")
		o.write(f"CraftForge.db.global.{filename} = {{\n")
		n.write(f"-- {basename2}\n")
		n.write("CraftForge.db.global.NameToSpellID = {\n")

		for spell_id in spell_to_skill_line:
			o.write(spells_list_str(spell_id, min_rank, trivial_low, trivial_high, spell_to_name))
			if spell_id in spell_to_name:
				name = re.sub(r' \|A:.*\|a', '', spell_to_name[spell_id]).replace('"', '\\"')
				n.write(f'["{name}"] = {spell_id},\n')

		o.write("}\n")
		n.write("}\n")


if len(sys.argv) < 2:
	print("Usage: SkillLevelsConverter2.py <SkillLineAbility.build.csv> [...]")
	sys.exit(1)

for csv_path in sys.argv[1:]:
	data = spells_list_read(csv_path)
	print(f"{len(data[0])} records processed in {csv_path}")
	spells_list_write(csv_path, data)
