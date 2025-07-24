defmodule NervesHubWeb.SessionControllerTest do
  use NervesHubWeb.ConnCase.Browser, async: true

  alias NervesHub.Fixtures

  setup do
    user =
      Fixtures.user_fixture(%{
        name: "Foo Bar",
        email: "foo@bar.com",
        password: "password"
      })

    org = Fixtures.org_fixture(user, %{name: "my_test_org_1"})
    {:ok, %{user: user, org: org}}
  end

  describe "new session" do
    test "renders form" do
      conn = build_conn()
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login"
    end
  end

  describe "create session" do
    test "redirected to the orgs page when logging in", %{user: user} do
      conn = build_conn()

      conn =
        post(
          conn,
          Routes.session_path(conn, :create),
          login: %{email: user.email, password: user.password}
        )

      assert redirected_to(conn) == "/orgs"
    end

    test "redirected to original URL when logging in", %{user: user} do
      conn =
        build_conn()
        |> get(~p"/orgs/new")
        |> post(
          ~p"/login",
          login: %{email: user.email, password: user.password}
        )

      assert redirected_to(conn) == ~p"/orgs/new"
    end

    test "redirected to MFA verification when user has MFA enabled", %{user: user} do
      # Enable MFA for user
      Fixtures.user_totp_fixture(%{user_id: user.id})

      conn =
        build_conn()
        |> post(~p"/login", login: %{email: user.email, password: user.password})

      assert redirected_to(conn) == "/mfa"

      # Check that user info is stored in session for MFA verification
      assert get_session(conn, :mfa_user_id) == user.id

      assert get_session(conn, :mfa_user_params) == %{
               "email" => user.email,
               "password" => user.password
             }
    end

    test "stores remember_me parameter for MFA flow", %{user: user} do
      # Enable MFA for user
      Fixtures.user_totp_fixture(%{user_id: user.id})

      conn =
        build_conn()
        |> post(~p"/login",
          login: %{email: user.email, password: user.password, remember_me: "true"}
        )

      assert redirected_to(conn) == "/mfa"
      assert get_session(conn, :mfa_user_id) == user.id
      user_params = get_session(conn, :mfa_user_params)
      assert user_params["remember_me"] == "true"
    end
  end
end
