defmodule JolaDev.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children = [
      JolaDevWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:jola_dev, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JolaDev.PubSub},
      {Finch, name: JolaDev.Finch},
      JolaDevWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: JolaDev.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    JolaDevWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
