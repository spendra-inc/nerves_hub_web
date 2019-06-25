defmodule NervesHubWWWWeb.LayoutView do
  use NervesHubWWWWeb, :view

  alias NervesHubWebCore.Accounts
  alias NervesHubWebCore.Accounts.User
  alias NervesHubWebCore.Products
  alias NervesHubWebCore.Products.Product

  @gravatar_url "https://secure.gravatar.com/avatar"
  @gravatar_size 54

  def product(%{assigns: %{product: %Product{} = product}}) do
    product
  end

  def product(_conn) do
    nil
  end

  def gravatar(%{assigns: %{user: %{email: email}}}) do
    hash = :crypto.hash(:md5, String.downcase(email)) |> Base.encode16(case: :lower)
    "#{@gravatar_url}/#{hash}?s=#{@gravatar_size}"
  end

  def user_orgs(%{assigns: %{user: %User{} = user}}) do
    Accounts.get_user_orgs_with_product_role(user, :read)
  end

  def user_orgs(_conn), do: []

  def user_org_products(user, org) do
    Products.get_products_by_user_and_org(user, org)
  end

  def logged_in?(%{assigns: %{user: %User{}}}), do: true
  def logged_in?(_), do: false

  def logo_href(conn) do
    if logged_in?(conn) do
      Routes.product_path(conn, :index, conn.assigns.user.username)
    else
      Routes.home_path(conn, :index)
    end
  end

  def has_org_role?(org, user, role) do
    Accounts.has_org_role?(org, user, role)
  end

  def health_status_icon(%{healthy: healthy?}) do
    {icon, color} = if healthy?, do: {"check-circle", "green"}, else: {"times-circle", "red"}
    content_tag(:i, "", class: "fas fa-#{icon}", style: "color:#{color}")
  end

  def health_status_icon(_) do
    content_tag(:i, "",
      class: "fas fa-question-circle",
      title: "Don't know how to tell health status"
    )
  end

  def help_icon(message, placement \\ :top) do
    content_tag(:i, "",
      class: "help-icon far fa-question-circle",
      data: [toggle: "help-tooltip", placement: placement],
      title: message
    )
  end

  def permit_uninvited_signups do
    Application.get_env(:nerves_hub_www, NervesHubWWWWeb.AccountController)[:allow_signups]
  end

  @tib :math.pow(2, 40)
  @gib :math.pow(2, 30)
  @mib :math.pow(2, 20)
  @kib :math.pow(2, 10)
  @precision 3

  def humanize_seconds(seconds) do
    seconds
    |> Timex.Duration.from_seconds()
    |> Timex.Format.Duration.Formatter.format(:humanized)
  end

  @doc """
  Note that results are in multiples of unit bytes: KiB, MiB, GiB
  [Wikipedia](https://en.wikipedia.org/wiki/Binary_prefix)
  """
  def humanize_size(bytes) do
    cond do
      bytes > @tib -> "#{Float.round(bytes / @gib, @precision)} TiB"
      bytes > @gib -> "#{Float.round(bytes / @gib, @precision)} GiB"
      bytes > @mib -> "#{Float.round(bytes / @mib, @precision)} MiB"
      bytes > @kib -> "#{Float.round(bytes / @kib, @precision)} KiB"
      true -> "#{bytes} bytes"
    end
  end

  @doc """
  Creates a series of pagination links to use with a Phoenix.LiveView page.

  When one of the links is clicked, it sends a `"paginate"` event with the
  expected page number for the LiveView to handle.

  Requires a map with `:total_pages` key or `:total_records` and `:page_size`
  keys to calculate `:total_pages` for you.

  Likewise, you can supply your list of records and applicable options (such
  as `:page_size`) to `pagination_links/2` which will calculate `:total_pages`
  for you.
  """
  def pagination_links(%{total_pages: _} = opts) do
    opts = Map.put_new(opts, :page_number, 1)

    content_tag(:div, class: "btn-group btn-group-toggle", data: [toggle: "buttons"]) do
      opts
      |> Scrivener.HTML.raw_pagination_links(distance: opts[:distance] || 8)
      |> Enum.map(fn {text, page} ->
        text = if text == :ellipsis, do: page, else: text

        content_tag(:button, text,
          phx_click: "paginate",
          phx_value: page,
          class: "btn btn-secondary btn-sm #{if page == opts.page_number, do: "active"}"
        )
      end)
    end
  end

  def pagination_links(%{total_records: record_count, page_size: size} = opts) do
    opts
    |> Map.put(:total_pages, ceil(record_count / size))
    |> pagination_links()
  end

  @doc """
  Like `pagination_links/1` but allows you to send a list which will be used
  to deduce `:total_pages` required to generate the links.
  """
  def pagination_links(records, opts \\ []) when is_list(records) do
    Map.new(opts)
    |> Map.put(:total_records, length(records))
    |> Map.put_new(:page_size, 20)
    |> pagination_links()
  end

  def sidebar_links(%{path_info: ["settings" | _tail]} = conn),
    do: sidebar_settings(conn)

  def sidebar_links(%{path_info: ["org", "new"]}),
    do: []

  def sidebar_links(%{path_info: ["org", _product_name]} = conn),
    do: sidebar_settings(conn)

  def sidebar_links(%{path_info: ["org", _product_name, "new"]} = conn),
    do: sidebar_settings(conn)

  def sidebar_links(%{path_info: ["org", _product_name | _tail]} = conn),
    do: sidebar_org(conn)

  def sidebar_links(_conn), do: []

  def sidebar_settings(%{assigns: %{user: user, org: org}} = conn) do
    ([
       %{
         title: "Products",
         icon: "boxes",
         active: "",
         href: Routes.product_path(conn, :index, conn.assigns.org.name)
       }
     ] ++
       if NervesHubWebCore.Accounts.has_org_role?(org, user, :read) do
         [
           %{
             title: "Profile",
             icon: "sliders-h",
             active: "",
             href: Routes.org_path(conn, :edit, conn.assigns.org.name)
           },
           %{
             title: "Certificate Authorities",
             icon: "certificate",
             active: "",
             href: Routes.org_certificate_path(conn, :index, conn.assigns.org.name)
           },
           %{
             title: "Firmware Keys",
             icon: "key",
             active: "",
             href: Routes.org_key_path(conn, :index, conn.assigns.org.name)
           },
           %{
             title: "Users",
             icon: "users",
             active: "",
             href: Routes.org_user_path(conn, :index, conn.assigns.org.name)
           }
         ]
       else
         []
       end ++
       if String.equivalent?(user.username, org.name) do
         [
           %{
             title: "My Account",
             icon: "id-card",
             active: "",
             href: Routes.account_path(conn, :edit, conn.assigns.user.username)
           }
         ]
       else
         []
       end)
    |> sidebar_active(conn)
  end

  def sidebar_org(conn) do
    [
      # %{title: "Dashboard", icon: "tachometer-alt", active: "", href: Routes.product_path(conn, :show, conn.assigns.org.name, conn.assigns.product.name)},
      %{
        title: "Devices",
        icon: "microchip",
        active: "",
        href: Routes.device_path(conn, :index, conn.assigns.org.name, conn.assigns.product.name)
      },
      %{
        title: "Firmware",
        icon: "sd-card",
        active: "",
        href: Routes.firmware_path(conn, :index, conn.assigns.org.name, conn.assigns.product.name)
      },
      %{
        title: "Deployments",
        icon: "cloud-download-alt",
        active: "",
        href:
          Routes.deployment_path(conn, :index, conn.assigns.org.name, conn.assigns.product.name)
      }
    ]
    |> sidebar_active(conn)
  end

  def sidebar_active(links, %{request_path: request_path}) do
    Enum.map(links, fn link ->
      if link.href == request_path do
        %{link | active: "active"}
      else
        link
      end
    end)
  end
end
