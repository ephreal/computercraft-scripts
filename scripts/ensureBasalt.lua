-- Merely ensures the basalt framework is present on the device
if not fs.exists("/modules/basalt.lua") then
    -- shell.run("cd", "/")
    shell.run("wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -r")

    if not fs.exists("/modules") then
        fs.makeDir("/modules")
    end

    fs.move("basalt.lua", "/modules/basalt.lua")
end
