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

function log(level, message)
    http.post
    {
        url = "https://turboco-app.azurewebsites.net/api/logs",
        body = "{ \"level\": " .. level .. ", \"message\": \"" .. message.replace("\"", "\\\"") .. "\" }",
        headers =
        {
            ["Content-Type"] = "application/json",
        }
    }
end

function updateRobot()
    local x, y, z = gps.locate()
    http.request
    {
        url = "https://turboco-app.azurewebsites.net/api/robots/" .. textutils.urlEncode(os.getComputerLabel()),
        method = "PUT",
        body = "{ \"x\": " .. x .. ", \"y\": " .. y .. ", \"z\": " .. z .. " }",
        headers =
        {
            ["Content-Type"] = "application/json",
        }
    }
end
