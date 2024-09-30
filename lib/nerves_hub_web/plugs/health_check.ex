defmodule NervesHubWeb.HealthCheck do
  @moduledoc """
  A plug that responds to /up with a 200 status code and an empty body.
  """
  import Plug.Conn
  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/up"} = conn, _opts) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
