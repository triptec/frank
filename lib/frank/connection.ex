defmodule Frank.Connection do
  use GenServer
  require Logger

  @timeout 30000

  def start_link(uri, opts \\ []) do
    GenServer.start_link(__MODULE__, uri, opts)
  end

  def init(uri) do
    {:ok, conn} = open_connection(uri)
    {:ok, chan} = open_channel(conn)
    Logger.info "#{inspect self} connected to: #{uri} with channel #{inspect chan}"
    {:ok, [uri, [conn, chan]]}
  end

  def connection(pid) do
    GenServer.call(pid, {:connection}, @timeout)
  end

  def connection_pid(pid) do
    GenServer.call(pid, {:connection_pid}, @timeout)
  end

  def channel(pid) do
    GenServer.call(pid, {:channel}, @timeout)
  end

  def channel_pid(pid) do
    GenServer.call(pid, {:channel_pid}, @timeout)
  end

  defp open_connection(uri) do
    {:ok, conn} = connect(uri)
    %AMQP.Connection{pid: conn_pid} = conn
    Process.monitor(conn_pid)
    {:ok, conn}
  end

  defp open_channel(conn) do
    {:ok, chan} = AMQP.Channel.open(conn)
    %AMQP.Channel{conn: _, pid: chan_pid} = chan
    Process.monitor(chan_pid)
    {:ok, chan}
  end

  defp connect(uri) do
    Logger.info "#{inspect self} connecting to: #{uri}"
    case AMQP.Connection.open(uri) do
      {:ok, conn} -> {:ok, conn}
      {:error, msg} -> retry(uri, msg)
    end
  end

  defp retry(uri, msg) do
    Logger.error("#{inspect self} connecting failed with: #{inspect(msg)}, retrying")
    :timer.sleep(1000)
    connect(uri)
  end

  def handle_call({:connection}, _from, state) do
    [_, [conn, _]] = state
    {:reply, conn, state}
  end

  def handle_call({:connection_pid}, _from, state) do
    [_, [conn, _]] = state
    %AMQP.Connection{pid: conn_pid} = conn
    {:reply, conn_pid, state}
  end

  def handle_call({:channel}, _from, state) do
    [_, [_, chan]] = state
    {:reply, chan, state}
  end

  def handle_call({:channel_pid}, _from, state) do
    [_, [_, chan]] = state
    %AMQP.Channel{conn: _, pid: chan_pid} = chan
    {:reply, chan_pid, state}
  end

  def handle_info({:DOWN, _, _, _, reason}, state) do
    [uri, [conn, _]] = state
    %AMQP.Connection{pid: conn_pid} = conn
    Logger.error "#{inspect self} connection to #{inspect conn_pid}: #{Process.alive?(conn_pid)}, reason: #{inspect reason}"
    Logger.info "Reconnecting.."
    {:ok, state} = init(uri)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error "Undefined msg"
    Logger.error "#{inspect msg}, #{inspect state}"
    {:noreply, state}
  end
end
