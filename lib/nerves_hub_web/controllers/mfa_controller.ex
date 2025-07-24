defmodule NervesHubWeb.MFAController do
  use NervesHubWeb, :controller

  alias NervesHub.MFA
  alias NervesHubWeb.Auth

  def new(conn, _params) do
    user_id = get_session(conn, :mfa_user_id)

    if user_id do
      render(conn, "new.html")
    else
      conn
      |> put_flash(:error, "Invalid session. Please log in again.")
      |> redirect(to: ~p"/login")
    end
  end

  def create(conn, %{"mfa" => %{"code" => code}}) do
    user_id = get_session(conn, :mfa_user_id)
    user_params = get_session(conn, :mfa_user_params) || %{}

    if user_id do
      user = NervesHub.Accounts.get_user!(user_id)

      case MFA.validate_user_totp(user, code) do
        :valid_totp ->
          conn
          |> delete_session(:mfa_user_id)
          |> delete_session(:mfa_user_params)
          |> Auth.log_in_user(user, user_params)

        {:valid_backup_code, remaining_codes} ->
          conn
          |> delete_session(:mfa_user_id)
          |> delete_session(:mfa_user_params)
          |> put_flash(
            :info,
            "Backup code used. You have #{remaining_codes} backup codes remaining."
          )
          |> Auth.log_in_user(user, user_params)

        :invalid ->
          conn
          |> put_flash(:error, "Invalid authentication code")
          |> render("new.html")
      end
    else
      conn
      |> put_flash(:error, "Invalid session. Please log in again.")
      |> redirect(to: ~p"/login")
    end
  end
end
