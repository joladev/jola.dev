defmodule JolaDevWeb.Plugs.RequestLogger do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  require Logger

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    started_at = System.monotonic_time()

    Logger.info("#{conn.method} #{conn.request_path}",
      request: %{
        method: conn.method,
        path: conn.request_path,
        query: query_params(conn),
        ip: client_ip(conn),
        headers: Map.new(conn.req_headers)
      }
    )

    register_before_send(conn, fn conn ->
      duration_ms =
        System.convert_time_unit(
          System.monotonic_time() - started_at,
          :native,
          :millisecond
        )

      Logger.info("Sent #{conn.status} in #{duration_ms}ms",
        response: %{
          status_code: conn.status,
          duration_ms: duration_ms,
          response_headers: Map.new(conn.resp_headers)
        }
      )

      conn
    end)
  end

  defp query_params(conn) do
    case conn.query_string do
      "" ->
        nil

      qs ->
        URI.decode_query(qs, %{})
    end
  end

  defp client_ip(conn) do
    with [val | _] <- get_req_header(conn, "x-forwarded-for"),
         [ip | _] <- String.split(val, ",") do
      String.trim(ip)
    end
  end
end
