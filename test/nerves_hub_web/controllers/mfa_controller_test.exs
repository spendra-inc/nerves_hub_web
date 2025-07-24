defmodule NervesHubWeb.MFAControllerTest do
  use NervesHubWeb.ConnCase.Browser, async: true

  alias NervesHub.Fixtures
  alias NervesHub.MFA

  setup do
    user =
      Fixtures.user_fixture(%{
        name: "Test User",
        email: "test@example.com",
        password: "password"
      })

    org = Fixtures.org_fixture(user, %{name: "test_org"})

    {:ok, %{user: user, org: org}}
  end

  describe "new/2" do
    test "renders MFA verification form when user_id is in session", %{user: user} do
      conn =
        build_conn()
        |> init_test_session(mfa_user_id: user.id)
        |> get(Routes.mfa_path(build_conn(), :new))

      assert html_response(conn, 200) =~ "Two-Factor Authentication"

      assert html_response(conn, 200) =~
               "Enter the authentication code from your authenticator app"

      assert html_response(conn, 200) =~ "Authentication Code"
    end

    test "redirects to login when no user_id in session" do
      conn = get(build_conn(), Routes.mfa_path(build_conn(), :new))

      assert redirected_to(conn) == "/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invalid session. Please log in again."
    end
  end

  describe "create/2" do
    setup %{user: user} do
      user_totp = Fixtures.user_totp_fixture(%{user_id: user.id})
      {:ok, %{user_totp: user_totp}}
    end

    test "logs in user with valid TOTP code", %{user: user} do
      user_totp = MFA.get_user_totp(user)
      valid_code = NimbleTOTP.verification_code(user_totp.secret)

      conn =
        build_conn()
        |> init_test_session(mfa_user_id: user.id)
        |> put_session(:mfa_user_params, %{"remember_me" => "true"})
        |> post(Routes.mfa_path(build_conn(), :create), %{
          "mfa" => %{"code" => valid_code}
        })

      assert redirected_to(conn) == "/orgs"
      assert get_session(conn, :mfa_user_id) == nil
      assert get_session(conn, :mfa_user_params) == nil
    end

    test "logs in user with valid backup code", %{user: user} do
      user_totp = MFA.get_user_totp(user)
      backup_code = List.first(user_totp.backup_codes).code

      conn =
        build_conn()
        |> init_test_session(mfa_user_id: user.id)
        |> put_session(:mfa_user_params, %{})
        |> post(Routes.mfa_path(build_conn(), :create), %{
          "mfa" => %{"code" => backup_code}
        })

      assert redirected_to(conn) == "/orgs"
      assert get_session(conn, :mfa_user_id) == nil
      assert get_session(conn, :mfa_user_params) == nil

      # Check that flash message about remaining backup codes is shown
      flash_message = Phoenix.Flash.get(conn.assigns.flash, :info)
      assert flash_message =~ "Backup code used"
      assert flash_message =~ "backup codes remaining"
    end

    test "shows error with invalid TOTP code", %{user: user} do
      conn =
        build_conn()
        |> init_test_session(mfa_user_id: user.id)
        |> post(Routes.mfa_path(build_conn(), :create), %{
          "mfa" => %{"code" => "123456"}
        })

      assert html_response(conn, 200) =~ "Two-Factor Authentication"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid authentication code"
      # Session should still contain user_id for retry
      assert get_session(conn, :mfa_user_id) == user.id
    end

    test "redirects to login when no user_id in session" do
      conn =
        build_conn()
        |> post(Routes.mfa_path(build_conn(), :create), %{
          "mfa" => %{"code" => "123456"}
        })

      assert redirected_to(conn) == "/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invalid session. Please log in again."
    end
  end
end
