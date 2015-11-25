defmodule Frank.Producer do
  use GenServer
  require Logger

  def start_link(opts, name) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(%{uri: uri}) do
    init %{uri: uri, exchange: ""}
  end

  def init(%{uri: uri, exchange: exchange}) do
    init %{uri: uri, exchange: exchange, routing_key: ""}
  end

  def init(%{uri: uri, exchange: exchange, routing_key: routing_key}) do
    {:ok, conn} = AMQP.Connection.open(uri)
    true = link_connection(conn)
    {:ok, chan} = AMQP.Channel.open(conn)
    {:ok, [chan, exchange, routing_key]}
  end

  def publish(pid, %{payload: payload, queue: queue}) do
    GenServer.call(pid, {:publish, %{payload: payload, queue: queue}})
  end

  def publish(pid, payload) do
    GenServer.call(pid, {:publish, %{payload: payload}})
  end

  defp publish(chan, exchange, routing_key, payload, opts) do
    AMQP.Basic.publish chan, exchange, routing_key, payload, opts
  end

  defp link_connection(conn) do
    %AMQP.Connection{pid: pid} = conn
    Process.link(pid)
  end

  def handle_call({:publish, %{payload: payload}}, _from, opts) do
    [chan, exchange, routing_key] = opts
    Logger.debug "Publishing payload: '#{inspect payload}' on exchange: '#{exchange}'"
    :ok = publish(chan, exchange, routing_key, payload, persistent: true)
    {:reply, payload, opts}
  end

  def handle_call({:publish, %{payload: payload, queue: queue}}, _from, opts) do
    [chan, exchange, _] = opts
    Logger.debug "Publishing payload: '#{inspect payload}' on exchange: '#{exchange}'"
    :ok = publish(chan, exchange, queue, payload, persistent: true)
    {:reply, payload, opts}
  end
end
