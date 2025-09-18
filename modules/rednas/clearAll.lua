function clear()
    for i=1,84,1 do
        fs.delete("/disk" .. i .. "/*")
    end
    fs.delete("/chunkMetadata/*")
end

clear()
