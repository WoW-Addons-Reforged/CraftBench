#!/usr/bin/python3
# Inspired by:
# https://github.com/Auctionator/Auctionator/blob/master/DB2_Scripts/convert-enchant-spell-to-enchant-mainline.py
#
# This script converts the csv output from:
# https://wago.tools/db2/Item
# https://wago.tools/db2/ItemEffect (Classic, row['ParentItemID'])
# https://wago.tools/db2/ItemXItemEffect (Retail only)
# https://wago.tools/db2/SpellName
#
# to get a mapping of the enchant spell id to the enchant item
# (for searching the AH for the enchant or
# calculation crafting profit), and spell level/equipped slot (for the vellum
# needed for crafting cost/profit)
#
# One command line argument of the form "5.5.0.62258" is added to the .csv file name(s)
#
import csv
import sys

if len(sys.argv) < 2:
	print("Usage: generate-scrollData-retail.py <build>")
	sys.exit(1)

build = sys.argv[1]

enchants_only = {}
with open('Item.' + build + '.csv', newline='', encoding='utf-8') as f:
	for row in csv.DictReader(f, delimiter=','):
		if row['ClassID'] == '8':  # Item Enhancement
			enchants_only[int(row['ID'])] = []

with open('ItemXItemEffect.' + build + '.csv', newline='', encoding='utf-8') as f:
	for row in csv.DictReader(f, delimiter=','):
		itemid = int(row['ItemID'])
		if itemid in enchants_only:
			enchants_only[itemid].append(int(row['ItemEffectID']))

effects_to_spell = {}
with open('ItemEffect.' + build + '.csv', newline='', encoding='utf-8') as f:
	for row in csv.DictReader(f, delimiter=','):
		effects_to_spell[int(row['ID'])] = int(row['SpellID'])

enchants_to_items = {}
for itemID, item_effects in enchants_only.items():
	if len(item_effects) == 1:
		spellID = effects_to_spell.get(item_effects[0])
		if spellID:
			enchants_to_items.setdefault(spellID, []).append(itemID)

spell_to_name = {}
with open('SpellName.' + build + '.csv', newline='', encoding='utf-8') as f:
	for row in csv.DictReader(f, delimiter=','):
		spell_to_name[int(row['ID'])] = row['Name_lang']

with open('scrollData.' + build + '.lua', 'w', encoding='utf-8', newline='\n') as o:
	o.write("-- " + build + "\n")
	o.write("CraftBench.scrollData = {\n")
	for spell_id, item_ids in enchants_to_items.items():
		spell_name = spell_to_name.get(spell_id, "")
		# Retail Enchants can create multiple scrolls (different iLvls).
		# Put the lowest id in the table and the complete list in the comment.
		if len(item_ids) > 1:
			item_ids.sort()
			o.write(f"\t[{spell_id}] = {item_ids[0]}, -- {spell_name} {item_ids}\n")
		else:
			o.write(f"\t[{spell_id}] = {item_ids[0]}, -- {spell_name}\n")
	o.write("}\n")
