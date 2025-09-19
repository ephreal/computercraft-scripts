-- Merely ensures the basalt framework is present on the device
if not fs.exists("/basalt") then
    shell.run("cd", "/")
    shell.run("wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -r")
end
