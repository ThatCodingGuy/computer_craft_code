local TURTLE_PROTOCOL = "turtle protocol"

local reverse_turtle = {}
for key, value in pairs(turtle) do
    reverse_turtle[value] = key
end

local function serialize(turtle_function, ...)

end

local function deserialize(turtle_function_call)
end

return {
    TURTLE_PROTOCOL = TURTLE_PROTOCOL,
    serialize = serialize,
    deserialize = deserialize,
}
