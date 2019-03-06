defmodule DockerClientTest do
  use ExUnit.Case

  test "ping" do
    {status, reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.ping()

    assert :ok == status
    assert reply == "OK"
  end

  test "get, create and prune network" do
    ## Prune Network all
    {status, _reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.prune_network()

    assert :ok == status

    ## Get Network
    {status, reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.get_network("launcher_test")

    assert :error == status
    assert reply == "network launcher_test not found"

    ## Create Network
    {status, %{"Id" => id, "Warning" => warn}} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.create_network("launcher_test")

    assert :ok == status
    assert id
    assert warn == ""

    ## Get Network
    {status, %{"Id" => iid, "Driver" => driver}} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.get_network("launcher_test")

    assert :ok == status
    assert id == iid
    assert "bridge" == driver

    ## Prune Network with delay of more than 30s
    {status, reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.prune_network("30s")

    assert :ok == status
    assert reply == %{"NetworksDeleted" => nil}

    ## Prune Network all
    {status, reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.prune_network()

    assert :ok == status
    assert reply == %{"NetworksDeleted" => ["launcher_test"]}
  end

  # XXX: Using static network for test, else create and prune
  test "create_container" do
    ## Create Network
    {status, %{"Id" => _id, "Warning" => _warn}} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.create_network("launcher")

    assert :ok == status

    options = %{
      publishallports: true,
      privileged: true,
      autoremove: true,
      network: "launcher",
      env: ["POSTGRES_PASSWORD=admin123"],
      image: "launcher:0.0.1",
      labels: %{ "a" => "b" },
      volumes: %{}
    }

    {status, reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.create_container("launcher_container", options)

    assert :ok == status

    %{"Id" => id} = reply

    {status, _reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.start_container(id)

    assert :ok == status

    {status, _reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.stop_container(id)

    assert :ok == status

    ## Prune Network all
    {status, _reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.prune_network()

    assert :ok == status
  end

  test "get_events" do
    until = DateTime.utc_now |> DateTime.to_unix
    since = until - (24*60*60)

    {status, _reply} =
      Anon.Docker.Client.default()
      |> Anon.Docker.new()
      |> Anon.Docker.get_events(since, until)

    assert :ok == status
  end
end
