--[[
 CraftForge: A tradeskill window replacement.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

-- German localizations provided by Farook (from wowinterface.com) and Stan (from wowace)

-- If you are doing localization and would like your name added here, please feel free
-- to do so, or let me know and I will be happy to add you to the credits
--[[
2009-10-14, RaverJK:
I did a complete review and proof reading  of the German translation. I changed a lot.
Many terms have been shortened to have the lables more intuitive and the descriptions
more... erm..  descriptive.
]]--

local L = LibStub("AceLocale-3.0"):NewLocale("CraftForge", "deDE")
if not L then return end

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", handle-subnamespaces="concat")@

L["Material Processing"] = "Materialverarbeitung"
L["PROCESSINGDESC"] = "Ein-Klick-Entzaubern, Sondieren, Mahlen und Schlossknacken (Molinari-Stil) konfigurieren"
L["PROCESSENABLEDNAME"] = "Ein-Klick-Materialverarbeitung aktivieren"
L["PROCESSENABLEDDESC"] = "Ermöglicht Entzaubern, Sondieren, Mahlen und Schlossknacken per Modifier-Taste + Klick direkt auf Taschen-Items"
L["PROCESSMODIFIERNAME"] = "Modifier-Taste"
L["PROCESSMODIFIERDESC"] = "Taste, die beim Überfahren und Anklicken von Taschen-Items gedrückt gehalten werden muss"
L["PROCESSMAXQUALITYNAME"] = "Max. Entzauber-Qualität"
L["PROCESSMAXQUALITYDESC"] = "Höchste Gegenstandsqualität, die per Ein-Klick entzaubert werden darf"
L["PROCESSDISENCHANTNAME"] = "Entzaubern aktivieren"
L["PROCESSDISENCHANTDESC"] = "Ein-Klick-Entzaubern für geeignete Ausrüstung erlauben"
L["PROCESSPROSPECTNAME"] = "Sondieren aktivieren"
L["PROCESSPROSPECTDESC"] = "Ein-Klick-Sondieren für Erz-Stapel ab 5 Stück erlauben"
L["PROCESSMILLNAME"] = "Mahlen aktivieren"
L["PROCESSMILLDESC"] = "Ein-Klick-Mahlen für Kräuter-Stapel ab 5 Stück erlauben"
L["PROCESSLOCKPICKNAME"] = "Schlossknacken aktivieren"
L["PROCESSLOCKPICKDESC"] = "Ein-Klick-Schlossknacken für verschlossene Truhen erlauben (Schurke)"
L["PROCESSGLOWNAME"] = "Leucht-Hervorhebung anzeigen"
L["PROCESSGLOWDESC"] = "Zeigt einen animierten Leuchtrahmen um verarbeitbare Items, solange die Modifier-Taste gehalten wird"
