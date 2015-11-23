defmodule Frank.Producer do
  use GenServer
  require Logger

  def start_link(opts, name) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(%{uri: uri, exchange: exchange}) do
    {:ok, conn} = AMQP.Connection.open(uri)
    true = link_connection(conn)
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Exchange.fanout(chan, exchange, durable: true)
    {:ok, [chan, exchange]}
  end

  def link_connection(conn) do
    %AMQP.Connection{pid: pid} = conn
    Process.link(pid)
  end

  def handle_call({:payload, payload}, _from, opts) do
    [chan, exchange] = opts
    Logger.debug "Publishing payload: '#{inspect payload}' on exchange: '#{exchange}'"
    :ok = AMQP.Basic.publish chan, exchange, "", payload, persistent: true
    {:reply, payload, opts}
  end

  def publish(pid, payload) do
    GenServer.call(pid, {:payload, payload})
  end
end
