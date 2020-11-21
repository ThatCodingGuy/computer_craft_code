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
