defmodule NervesHubWeb.HealthCheckTest do
  use NervesHubWeb.ConnCase.Browser, async: true

  test "returns 200 for /up path", %{conn: conn} do
    conn = get(conn, "/up")

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ""
    assert conn.halted
  end

  test "passes through for other paths", %{conn: conn} do
    conn = get(conn, "/other")
    assert conn.status == 404
  end
end
