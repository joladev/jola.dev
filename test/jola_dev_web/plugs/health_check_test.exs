defmodule JolaDevWeb.Plugs.HealthCheckTest do
  use JolaDevWeb.ConnCase, async: true
  alias JolaDevWeb.Plugs.HealthCheck

  describe "call/2" do
    test "returns 200 status for /health path", %{conn: conn} do
      conn =
        conn
        |> Map.put(:request_path, "/health")
        |> HealthCheck.call([])

      assert conn.status == 200
      assert conn.resp_body == ""
      assert conn.halted
    end

    test "passes through non-health paths unchanged", %{conn: conn} do
      original_conn = Map.put(conn, :request_path, "/other-path")
      result_conn = HealthCheck.call(original_conn, [])

      assert result_conn == original_conn
      refute result_conn.halted
    end
  end

  describe "init/1" do
    test "returns empty list" do
      assert HealthCheck.init(:anything) == []
    end
  end
end
