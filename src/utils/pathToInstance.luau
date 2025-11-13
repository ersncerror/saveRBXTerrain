return function(path: string): Instance | nil
    local parts = string.split(path, ".")

    local current = game:GetService(parts[1])

    for i = 2, #parts do
        
        if current:FindFirstChild(parts[i]) then
            current = current:FindFirstChild(parts[i])
        else
            return nil
        end

    end

    return current
end