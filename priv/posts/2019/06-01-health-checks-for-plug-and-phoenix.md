%{
  title: "Health checks for Plug and Phoenix",
  author: "Johanna Larsson",
  tags: ~w(phoenix plug elixir),
  description: "I want to share a simple pattern for setting up HTTP based health checks for Plug/Phoenix applications"
}
---
I want to share a simple pattern for setting up HTTP based health checks for Plug/Phoenix applications. Health checks can be used for anything from uptime measuring to readiness/liveness probes for platforms like Kubernetes och ECS. The most simple version of one accepts requests on some specific path and responds with a 200. Another consideration is that it might run very frequently (ECS by default checks around 6 times a second) so it’s also ideal to run it as light as possible, and not generate logs. Finally, personally, I prefer having it out of the way of routing and controllers because I see it as separate from the functionality of the application. *Skip to the bottom for a suggestion on how to avoid logging health checks in Phoenix while still using `Phoenix.Router`.*

This code example works even if you don’t use Phoenix since it’s just a plug.

```elixir
defmodule HealthCheck do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/health_check"} = conn, _opts) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
```

To just briefly explain it, it will grab any request with the specified `request_path` and immediately respond with an empty 200. All other requests are passed through untouched.

You use it by adding it to the top of your plugs. Here’s an example based on the default Phoenix project, in the `Endpoint.ex` file:

```elixir
# hello_web/Endpoint.ex
defmodule HelloWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hello

  # Put the health check here, before anything else
  plug HealthCheck

  socket "/socket", HelloWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :hello,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
...
```

The reason you want it first is that it short circuits any requests to the path `/health_check`, meaning no other plugs are executed. This has two primary benefits: the first one being that you avoid unnecessary CPU cycles (no router etc). And the other being that it doesn’t get logged because it runs before `Plug.Logger`.

If you now try going to `/health_check` you’ll see that no request is logged and you get an empty successful response.

So there you are, a very simple pattern for handling health checks in Plug and Phoenix. You don’t have to limit yourself to just responding 200, you can do any checks in that function clause and return anything, so feel free to adjust and improve for your use case.

If you’re not like me, and you feel strongly that the health check should be in your router (and you’re using Phoenix), but you don’t want those requests to be logged, take a look at `scope/2`. It supports setting the log level for requests for a specific scope, or even turning request logging off completely for them. Here’s an example:

```elixir
  scope "/health_check", log: false do
    forward "/", HealthCheck
  end
```

Enjoy!
