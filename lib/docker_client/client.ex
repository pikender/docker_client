defmodule Anon.Docker.Client do
  use Tesla

  alias Util.Config
  alias __MODULE__

  defstruct [
    :host,
    :agent
  ]

  plug Tesla.Middleware.JSON
  adapter(Tesla.Adapter.Hackney, ssl: Config.get!(:docker_client, :ssl_options))

  def default do
    %__MODULE__{host: Config.get!(:docker_client, :docker_address)}
  end

  def new(%Client{} = client) do
    agent =
      Tesla.build_client([
        {Tesla.Middleware.BaseUrl, client.host},
      ])

    %Client{client | agent: agent}
  end

  def ping(%Client{agent: agent}) do
    agent
    |> get("/_ping")
    |> handle_get()
  end

  def get_network(%Client{agent: agent}, name) do
    agent
    |> get("/networks/#{name}")
    |> handle_get()
  end

  def create_network(%Client{agent: agent}, name) do
    agent
    |> post("/networks/create", create_network_data(name))
    |> handle_post()
  end

  defp create_network_data(name) do
    %{
      "Name" => name,
      "Driver" => "bridge",
      "CheckDuplicate" => true
    }
  end

  def prune_network(%Client{agent: agent}, until) do
    agent
    |> post("/networks/prune", %{}, query: prune_network_data(until))
    |> handle_post()
  end

  defp prune_network_data(nil) do
    []
  end

  defp prune_network_data(until) do
    [
      filters: Poison.encode!(%{
        until: %{until => true}
      })
    ]
  end

  def create_container(%Client{agent: agent}, name, options) do
    agent
    |> post("/containers/create", create_container_data(options), query: [name: name])
    |> handle_post()
  end

  defp create_container_data(options) do
    %{
      "HostConfig" => %{
        "PublishAllPorts" => options[:publishallports],
        "Privileged" => options[:privileged],
        "AutoRemove" => options[:autoremove],
        "NetworkMode" => options[:network],
        "Binds" => options[:binds],
        "ExtraHosts" => options[:extra_hosts]
      },
      "Env" => options[:env],
      "Image" => options[:image],
      "Labels" => options[:labels],
      "Volumes" => options[:volumes],
      "Cmd" => options[:cmd]
    }
  end

  def start_container(%Client{agent: agent}, name) do
    agent
    |> post("containers/#{name}/start", %{})
    |> handle_post()
  end

  # XXX: 30 secs wait
  def stop_container(%Client{agent: agent}, name) do
    agent
    |> post("containers/#{name}/stop", %{}, query: [t: 30], opts: [recv_timeout: 60_000])
    |> handle_post()
  end

  def container_logs(client, name) do
    get("_ping")
  end

  def get_events(%Client{agent: agent} = client, since, until) do
    Client.Event.get_events(client, since, until)
  end

  def handle_get(%{status: status} = response) when status < 300 do
    {:ok, response.body}
  end

  def handle_get(response) do
    {:error, error_message(response)}
  end

  defp error_message(%{body: %{"message" => msg}}) do
    msg
  end

  defp error_message(%{body: body}) do
    inspect(body)
  end

  defp handle_post(%{status: status} = response) when status < 300 do
    {:ok, response.body}
  end

  defp handle_post(response) do
    {:error, error_message(response)}
  end

  defimpl Anon.Docker do
    def new(client) do
      Client.new(client)
    end

    def ping(client) do
      Client.ping(client)
    end

    def get_network(client, name) do
      Client.get_network(client, name)
    end

    def create_network(client, name) do
      Client.create_network(client, name)
    end

    def prune_network(client, until) do
      Client.prune_network(client, until)
    end

    def create_container(client, name, options) do
      Client.create_container(client, name, options)
    end

    def start_container(client, name) do
      Client.start_container(client, name)
    end

    def stop_container(client, name) do
      Client.stop_container(client, name)
    end

    def container_logs(client, name) do
      Client.container_logs(client, name)
    end

    def get_events(client, since, until) do
      Client.get_events(client, since, until)
    end
  end
end
