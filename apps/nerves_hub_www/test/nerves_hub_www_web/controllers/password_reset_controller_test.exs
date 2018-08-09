defmodule NervesHubWWWWeb.PasswordResetControllerTest do
  use NervesHubWWWWeb.ConnCase
  use Bamboo.Test

  alias NervesHubCore.Fixtures
  alias NervesHubCore.Accounts

  describe "new password_reset" do
    test "renders form", %{conn: conn} do
      conn = get(conn, password_reset_path(conn, :new))
      assert html_response(conn, 200) =~ "Reset Password"
    end
  end

  describe "create password_reset" do
    setup [:create_user]

    test "with valid params", %{conn: conn, user: user} do
      params = %{"password_reset" => %{"email" => user.email}}

      reset_conn = post(conn, password_reset_path(conn, :create), params)

      assert redirected_to(reset_conn) == session_path(reset_conn, :new)

      {:ok, updated_user} = Accounts.get_user(user.id)
      assert_delivered_email(NervesHubWWW.Accounts.Email.forgot_password(updated_user))
    end

    test "with invalid params", %{conn: conn} do
      params = %{}

      reset_conn = post(conn, password_reset_path(conn, :create), params)
      assert html_response(reset_conn, 200) =~ "You must enter an email address."
    end
  end

  describe "reset password" do
    setup [:create_user]

    test "new_password_form with invalid token", %{conn: conn, user: user} do
      params = %{"user" => %{"email" => user.email}}

      reset_conn =
        get(conn, password_reset_path(conn, :new_password_form, "not a good token"), params)

      assert redirected_to(reset_conn) == session_path(reset_conn, :new)
    end

    test "new_password_form with valid token", %{conn: conn, user: user} do
      params = %{"user" => %{"email" => user.email}}

      token =
        Accounts.update_password_reset_token(user.email)
        |> elem(1)
        |> Map.get(:password_reset_token)

      reset_conn = get(conn, password_reset_path(conn, :new_password_form, token), params)

      assert html_response(reset_conn, 200) =~ "New Password:"
    end

    test "with valid params", %{conn: conn, user: user} do
      params = %{"user" => %{"password" => "new password"}}

      token =
        Accounts.update_password_reset_token(user.email)
        |> elem(1)
        |> Map.get(:password_reset_token)

      reset_conn = put(conn, password_reset_path(conn, :reset, token), params)
      assert redirected_to(reset_conn) == session_path(reset_conn, :new)

      # enforce side effect
      {:ok, updated_user} = Accounts.get_user(user.id)
      refute updated_user.password_hash == user.password_hash
    end

    test "with invalid params", %{conn: conn, user: user} do
      params = %{"user" => %{}}

      token =
        Accounts.update_password_reset_token(user.email)
        |> elem(1)
        |> Map.get(:password_reset_token)

      reset_conn = put(conn, password_reset_path(conn, :reset, token), params)
      assert html_response(reset_conn, 200) =~ "You must provide a new password."

      # enforce side effect
      {:ok, updated_user} = Accounts.get_user(user.id)
      assert updated_user.password_hash == user.password_hash
    end

    test "with invalid token", %{conn: conn, user: user} do
      params = %{"user" => %{"email" => user.email, "password" => "new password"}}

      bad_token = Ecto.UUID.bingenerate()

      reset_conn = put(conn, password_reset_path(conn, :reset, bad_token), params)
      assert redirected_to(reset_conn) == session_path(reset_conn, :new)

      # enforce side effect
      {:ok, updated_user} = Accounts.get_user(user.id)
      assert updated_user.password_hash == user.password_hash
    end
  end

  defp create_user(_) do
    org = Fixtures.org_fixture()
    user = Fixtures.user_fixture(org)
    {:ok, user: user}
  end
end