-- Luacheck configuration for WoW Addon
std = "lua51"
unused_args = false
max_line_length = 160

globals = {
    "LibStub",
    "Skillet",
}

ignore = {
    "111",
    "112",
    "113",
    "211",
    "212",
    "213",
    "311",
    "411",
    "412",
    "421",
    "422",
    "512",
    "542",
    "611",
    "612",
    "613",
    "614",
}

exclude_files = {
    "SkillLevelData1.lua",
    "SkillLevelData12.lua",
    "Locale/**",
}

files = {}
files["libs/"] = {
    ignore = { "1", "2", "3", "4", "5", "6" }
}
files["Libs/"] = {
    ignore = { "1", "2", "3", "4", "5", "6" }
}
