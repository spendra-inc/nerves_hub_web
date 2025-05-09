defmodule NervesHubWeb.Live.Devices.IndexTest do
  use NervesHubWeb.ConnCase.Browser, async: false

  alias NervesHub.Devices
  alias NervesHub.Fixtures

  alias NervesHub.Repo

  alias NervesHubWeb.Endpoint

  setup %{fixture: %{device: device}} do
    Endpoint.subscribe("device:#{device.id}")
  end

  describe "handle_event" do
    test "filters devices by exact identifier", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier

      change = render_change(view, "update-filters", %{"device_id" => device.identifier})
      assert change =~ device.identifier
      refute change =~ device2.identifier
      assert change =~ "1 devices found"
    end

    test "filters devices by wrong identifier", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier

      change = render_change(view, "update-filters", %{"device_id" => "foo"})
      refute change =~ device.identifier
      refute change =~ device2.identifier
      assert change =~ "0 devices found"
    end

    test "filters devices by prefix identifier", %{conn: conn, fixture: fixture} do
      %{device: device} = fixture

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier

      assert render_change(view, "update-filters", %{"device_id" => "device-"}) =~
               device.identifier
    end

    test "filters devices by suffix identifier", %{conn: conn, fixture: fixture} do
      %{device: device} = fixture

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      "device-" <> tail = device.identifier

      assert render_change(view, "update-filters", %{"device_id" => tail}) =~
               device.identifier
    end

    test "filters devices by middle identifier", %{conn: conn, fixture: fixture} do
      %{device: device} = fixture

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier

      assert render_change(view, "update-filters", %{"device_id" => "ice-"}) =~
               device.identifier
    end

    test "filters devices by tag", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware, %{tags: ["filtertest"]})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device2.identifier

      refute render_change(view, "update-filters", %{"tag" => "filtertest-noshow"}) =~
               device2.identifier

      assert render_change(view, "update-filters", %{"tag" => "filtertest"}) =~
               device2.identifier
    end

    test "filters devices by metrics", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware, %{})
      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier

      # Add metrics for device2, sleep between to secure order.
      Devices.Metrics.save_metric(%{device_id: device2.id, key: "cpu_temp", value: 36})
      :timer.sleep(100)
      Devices.Metrics.save_metric(%{device_id: device2.id, key: "cpu_temp", value: 42})
      :timer.sleep(100)
      Devices.Metrics.save_metric(%{device_id: device2.id, key: "load_1min", value: 3})

      change =
        render_change(view, "update-filters", %{
          "metrics_key" => "cpu_temp",
          "metrics_operator" => "gt",
          "metrics_value" => "37"
        })

      # Show only show device2, which has a value greater than 37 on most recent cpu_temp metric.
      assert change =~ device2.identifier
      refute change =~ device.identifier

      change2 =
        render_change(view, "update-filters", %{
          "metrics_key" => "cpu_temp",
          "metrics_operator" => "lt",
          "metrics_value" => "37"
        })

      # Should not show any device since the query is for values less than 37
      refute change2 =~ device2.identifier
      refute change2 =~ device.identifier
    end

    test "filters devices by several tags", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      device2 =
        Fixtures.device_fixture(org, product, firmware, %{tags: ["filtertest", "testfilter"]})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device2.identifier

      refute render_change(view, "update-filters", %{"tag" => "filtertest-noshow"}) =~
               device2.identifier

      assert render_change(view, "update-filters", %{"tag" => "filtertest"}) =~
               device2.identifier

      assert render_change(view, "update-filters", %{"tag" => "filtertest, testfilter"}) =~
               device2.identifier
    end

    test "filters devices with no tags", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware, %{tags: nil})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device2.identifier

      refute render_change(view, "update-filters", %{"tag" => "doesntmatter"}) =~
               device2.identifier
    end

    test "filters devices with only untagged", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware, %{tags: nil})
      device3 = Fixtures.device_fixture(org, product, firmware, %{tags: ["foo"]})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device2.identifier
      assert html =~ device3.identifier

      change = render_change(view, "update-filters", %{"has_no_tags" => "true"})
      assert change =~ device2.identifier
      refute change =~ device3.identifier
    end

    test "filters devices with alarms", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier
      assert html =~ "2 devices found"

      device_health = %{"device_id" => device.id, "data" => %{"alarms" => %{"SomeAlarm" => []}}}
      assert {:ok, _} = NervesHub.Devices.save_device_health(device_health)

      change = render_change(view, "update-filters", %{"alarm_status" => "with"})
      assert change =~ device.identifier
      refute change =~ device2.identifier
      assert change =~ "1 devices found"
    end

    test "filters devices without alarms", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier
      assert html =~ "2 devices found"

      device_health = %{"device_id" => device.id, "data" => %{"alarms" => %{"SomeAlarm" => []}}}
      assert {:ok, _} = NervesHub.Devices.save_device_health(device_health)

      change = render_change(view, "update-filters", %{"alarm_status" => "without"})
      refute change =~ device.identifier
      assert change =~ device2.identifier
      assert change =~ "1 devices found"
    end

    test "filters devices with specific alarm", %{conn: conn, fixture: fixture} do
      %{device: device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ device.identifier
      assert html =~ device2.identifier
      assert html =~ "2 devices found"

      alarm = "SomeAlarm"
      device_health = %{"device_id" => device.id, "data" => %{"alarms" => %{alarm => []}}}
      assert {:ok, _} = NervesHub.Devices.save_device_health(device_health)

      change = render_change(view, "update-filters", %{"alarm" => alarm})
      assert change =~ device.identifier
      refute change =~ device2.identifier
      assert change =~ "1 devices found"
    end

    test "filters devices by deployment group", %{conn: conn, fixture: fixture} do
      %{
        device: device,
        firmware: firmware,
        org: org,
        product: product,
        deployment_group: deployment_group
      } =
        fixture

      device2 = Fixtures.device_fixture(org, product, firmware)

      Repo.update!(Ecto.Changeset.change(device, deployment_id: deployment_group.id))

      {:ok, view, _html} = live(conn, device_index_path(fixture))

      change = render_change(view, "update-filters", %{"deployment_id" => deployment_group.id})
      assert change =~ device.identifier
      refute change =~ device2.identifier
      assert change =~ "1 devices found"
    end

    test "filters devices by no deployment", %{conn: conn, fixture: %{device: device} = fixture} do
      refute device.deployment_id

      {:ok, view, _html} = live(conn, device_index_path(fixture))

      # -1 is a UI concern that indicates we're filtering for devices that have no deployment
      change = render_change(view, "update-filters", %{"deployment_id" => "-1"})
      assert change =~ device.identifier
      assert change =~ "1 devices found"
    end

    test "select device", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      device2 = Fixtures.device_fixture(org, product, firmware, %{tags: nil})
      _device3 = Fixtures.device_fixture(org, product, firmware, %{tags: ["foo"]})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ "3 devices found"
      refute html =~ "(1 selected)"

      change = render_change(view, "select", %{"id" => device2.id})
      assert change =~ "3 devices found"
      assert change =~ "(1 selected)"
    end

    test "select/deselect all devices", %{conn: conn, fixture: fixture} do
      %{device: _device, firmware: firmware, org: org, product: product} = fixture

      _device2 = Fixtures.device_fixture(org, product, firmware, %{tags: nil})
      _device3 = Fixtures.device_fixture(org, product, firmware, %{tags: ["foo"]})

      {:ok, view, html} = live(conn, device_index_path(fixture))
      assert html =~ "3 devices found"

      change = render_change(view, "select-all", %{})
      assert change =~ "3 devices found"
      assert change =~ "(3 selected)"

      change = render_change(view, "select-all", %{})
      assert change =~ "3 devices found"
      refute change =~ "selected)"
    end
  end

  describe "bulk actions" do
    test "changes tags", %{conn: conn, fixture: fixture} do
      %{device: device, org: org, product: product} = fixture

      conn
      |> visit("/org/#{org.name}/#{product.name}/devices")
      |> assert_has("h1", text: "Devices")
      |> assert_has("span", text: "beta")
      |> assert_has("span", text: "beta-edge")
      |> unwrap(fn view ->
        render_change(view, "select", %{"id" => device.id})
      end)
      |> fill_in("Set tag(s) to:", with: "moussaka")
      |> click_button("Set")
      |> assert_has("span", text: "moussaka")
    end

    test "add multiple devices to deployment in old UI",
         %{conn: conn, fixture: fixture} do
      %{
        device: device,
        org: org,
        product: product,
        firmware: firmware,
        deployment_group: deployment_group
      } = fixture

      device2 = Fixtures.device_fixture(org, product, firmware)
      Endpoint.subscribe("device:#{device2.id}")

      refute device.deployment_id
      refute device2.deployment_id

      conn
      |> visit(
        "/org/#{org.name}/#{product.name}/devices?platform=#{deployment_group.firmware.platform}"
      )
      |> unwrap(fn view ->
        render_change(view, "select-all", %{"id" => device.id})
      end)
      |> assert_has("span", text: "2 selected")
      |> select("Move device(s) to deployment group:",
        option: deployment_group.name,
        exact_option: false
      )
      |> click_button("#move-deployment-group-submit", "Move")
      |> assert_has("div", text: "2 devices added to deployment")

      assert_receive %{event: "devices/updated"}
      assert_receive %{event: "devices/updated"}

      assert Repo.reload(device) |> Map.get(:deployment_id)
      assert Repo.reload(device2) |> Map.get(:deployment_id)
    end
  end

  def device_index_path(%{org: org, product: product}) do
    ~p"/org/#{org.name}/#{product.name}/devices"
  end
end
