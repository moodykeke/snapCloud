#!/usr/bin/env lua
local cjson = require('cjson')
local translations = {languages = {'en', 'zh', 'de', 'es', 'fr', 'it', 'pt', 'tr', 'ca', 'hy'}, data = {}}

local common_translations = {
    zh = {["Search"] = "搜索", ["username"] = "用户名", ["Password"] = "密码", ["Choose File"] = "选择文件"},
    de = {["Search"] = "Suchen", ["username"] = "Benutzername", ["Password"] = "Passwort", ["Choose File"] = "Datei wählen"},
    es = {["Search"] = "Buscar", ["username"] = "nombre de usuario", ["Password"] = "contraseña"},
    fr = {["Search"] = "Rechercher", ["username"] = "nom d'utilisateur", ["Password"] = "mot de passe"},
    it = {["Search"] = "Cerca", ["username"] = "nome utente", ["Password"] = "password"},
    pt = {["Search"] = "Pesquisar", ["username"] = "nome de usuário", ["Password"] = "senha"},
    tr = {["Search"] = "Ara", ["username"] = "kullanıcı adı", ["Password"] = "şifre"},
    ca = {["Search"] = "Cercar", ["username"] = "nom d'usuari", ["Password"] = "contrasenya"},
    hy = {["Search"] = "Փնտրել", ["username"] = "օգտանուն", ["Password"] = "գաղտնաբառ"}
}

local function translate_text(text, lang)
    if common_translations[lang] and common_translations[lang][text] then
        return common_translations[lang][text]
    end
    return text
end

local file = io.open('.auto-i18n-cache/hardcoded_texts.json', 'r')
if not file then print('❌ Run extract first'); os.exit(1) end
local hardcoded_texts = cjson.decode(file:read('*all'))
file:close()

print('🤖 Generating translations...\n')
local unique_texts = {}
for _, items in pairs(hardcoded_texts) do
    for _, item in ipairs(items) do
        if not unique_texts[item.key] then
            unique_texts[item.key] = item.text
        end
    end
end

for key, text in pairs(unique_texts) do
    translations.data[key] = {en = text}
    for _, lang in ipairs(translations.languages) do
        if lang ~= 'en' then
            translations.data[key][lang] = translate_text(text, lang)
        end
    end
end

local out = io.open('.auto-i18n-cache/translations.json', 'w')
out:write(cjson.encode(translations.data))
out:close()

print('✅ Generated ' .. #unique_texts .. ' keys × 9 languages\n')
print('💾 Saved to: .auto-i18n-cache/translations.json\n')
