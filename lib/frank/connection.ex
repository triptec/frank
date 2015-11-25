defmodule Frank.Connection do
  use GenServer
  require Logger

  def start_link(uri, opts \\ []) do
    GenServer.start_link(__MODULE__, uri, opts)
  end

  def init(uri) do
    {:ok, conn_pid} = open(uri)
    Logger.info "Connected to: #{uri}"
    {:ok, [uri, conn_pid]}
  end

  defp open(uri) do
    {:ok, conn} = connect(uri)
    %AMQP.Connection{pid: conn_pid} = conn
    Process.monitor(conn_pid)
    {:ok, conn_pid}
  end

  defp connect(uri) do
    Logger.info "Connecting to: #{uri}"
    case AMQP.Connection.open(uri) do
      {:ok, conn} -> {:ok, conn}
      {:error, msg} -> retry(uri, msg)
    end
  end

  defp retry(uri, msg) do
    Logger.error(inspect(msg))
    :timer.sleep(1000)
    connect(uri)
  end

  def handle_info({:DOWN, _, _, _, reason}, state) do
    [uri, conn_pid] = state
    Logger.error "Connection: #{Process.alive?(conn_pid)}, reason: #{inspect reason}"
    Logger.info "Reconnecting.."
    {:ok, state} = init(uri)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error "#{inspect msg}, #{inspect state}"
    {:noreply, state}
  end
end
