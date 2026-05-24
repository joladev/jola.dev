defmodule JolaDevWeb.Plugs.RequestLoggerTest do
  use JolaDevWeb.ConnCase, async: true

  alias JolaDevWeb.Plugs.RequestLogger

  defmodule TestHandler do
    @moduledoc false

    def log(%{meta: %{pid: source_pid}} = event, %{config: %{test_pid: test_pid}})
        when source_pid == test_pid do
      send(test_pid, {:log_event, event})
      :ok
    end

    def log(_event, _config), do: :ok
  end

  setup do
    Logger.reset_metadata()
    Logger.put_module_level(JolaDevWeb.Plugs.RequestLogger, :info)

    handler_id = String.to_atom("rlt_#{System.unique_integer([:positive])}")

    :ok =
      :logger.add_handler(handler_id, TestHandler, %{
        config: %{test_pid: self()},
        level: :info
      })

    on_exit(fn ->
      :logger.remove_handler(handler_id)
      Logger.delete_module_level(JolaDevWeb.Plugs.RequestLogger)
    end)

    :ok
  end

  defp call_plug(conn) do
    RequestLogger.call(conn, RequestLogger.init([]))
  end

  defp message(event) do
    {:string, msg} = event.msg
    IO.iodata_to_binary(msg)
  end

  describe "call/2 request log" do
    test "emits structured request fields on entry", %{conn: conn} do
      conn
      |> Map.put(:method, "POST")
      |> Map.put(:request_path, "/api/probe/results")
      |> put_req_header("x-forwarded-for", "203.0.113.42")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer secret")
      |> call_plug()

      assert_receive {:log_event, event}
      assert message(event) == "POST /api/probe/results"

      meta = event.meta
      assert meta.request.method == "POST"
      assert meta.request.path == "/api/probe/results"
      assert meta.request.query == nil
      assert meta.request.ip == "203.0.113.42"
      assert is_map(meta.request.headers)
      assert Map.has_key?(meta.request.headers, "content-type")
      assert Map.has_key?(meta.request.headers, "authorization")
    end

    test "sets query to nil when query string is empty", %{conn: conn} do
      conn
      |> Map.put(:query_string, "")
      |> call_plug()

      assert_receive {:log_event, event}
      assert event.meta.request.query == nil
    end

    test "extracts client IP from X-Forwarded-For", %{conn: conn} do
      conn
      |> put_req_header("x-forwarded-for", "203.0.113.42, 198.51.100.1")
      |> call_plug()

      assert_receive {:log_event, event}
      assert event.meta.request.ip == "203.0.113.42"
    end

    test "IP is [] when X-Forwarded-For header is missing", %{conn: conn} do
      call_plug(conn)

      assert_receive {:log_event, event}
      assert event.meta.request.ip == []
    end
  end

  describe "call/2 response log via register_before_send" do
    test "emits structured response fields when send_resp fires", %{conn: conn} do
      conn
      |> call_plug()
      |> put_resp_header("content-type", "application/json")
      |> put_resp_header("cache-control", "no-cache")
      |> Plug.Conn.send_resp(201, "ok")

      assert_receive {:log_event, _request_event}
      assert_receive {:log_event, response_event}

      assert message(response_event) =~ ~r/^Sent 201 in \d+ms$/
      assert response_event.meta.response.status_code == 201
      assert is_integer(response_event.meta.response.duration_ms)
      assert response_event.meta.response.duration_ms >= 0
      assert is_map(response_event.meta.response.response_headers)

      assert response_event.meta.response.response_headers == %{
               "content-type" => "application/json",
               "cache-control" => "no-cache"
             }
    end
  end

  describe "process metadata isolation" do
    test "structured fields do not leak into Logger.metadata after the request", %{conn: conn} do
      conn
      |> put_req_header("user-agent", "something/0.1.0")
      |> call_plug()
      |> Plug.Conn.send_resp(200, "ok")

      meta = Logger.metadata()
      refute Keyword.has_key?(meta, :request)
      refute Keyword.has_key?(meta, :response)
    end
  end
end
