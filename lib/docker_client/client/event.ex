defmodule Anon.Docker.Client.Event do
  use Tesla

  alias Util.Config
  alias Anon.Docker.Client

  adapter(Tesla.Adapter.Hackney, ssl: Config.get!(:docker_client, :ssl_options))

  def get_events(%Client{agent: agent}, since, until) do
    agent
    |> get("/events", query: [since: since, until: until])
    |> Client.handle_get()
    |> process_response()
  end

  defp process_response({:ok, resp}) do
    res =
      resp
      |> String.split(["\n", "\r", "\r\n"])
      |> decode_event([])
      |> Enum.reverse()
    {:ok, res}
  end

  defp process_response(resp) do
    resp
  end

  defp decode_event([""], res), do: res
  defp decode_event([], res), do: res
  defp decode_event([el|rem], res) do
    decode_event(rem, [Poison.decode!(el) | res])
  end
end
