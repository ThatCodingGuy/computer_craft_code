function alert(message)
    http.post
    {
        url = "https://turboco-app.azurewebsites.net/api/alerts",
        body = "{ \"message\": \"" .. message .. "\" }",
        headers =
        {
            ["Content-Type"] = "application/json",
        }
    }
end

function updateRobot()
    local x, y, z = gps.locate()
    print("Name=" .. os.getComputerLabel())
    print("X=" .. x)
    print("Y=" .. y)
    print("Z=" .. z)
    http.request
    {
        url = "https://turboco-app.azurewebsites.net/api/robots/" .. os.getComputerLabel(),
        method = "PUT",
        body = "{ \"x\": \"" .. x .. "\", \"y\": \"" .. y .. "\", \"z\": \"" .. z .. "\" }",
        headers =
        {
            ["Content-Type"] = "application/json",
        }
    }
end
