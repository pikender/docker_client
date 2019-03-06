defprotocol Anon.Docker do
  def new(client)

  def ping(client)

  def get_network(client, name)
  def create_network(client, name)
  def prune_network(client, until \\ nil)

  def create_container(client, name, options)
  def start_container(client, name)
  def stop_container(client, name)

  def container_logs(client, name)

  def get_events(client, since, until)
end
