defmodule Frank.Consumer do
  require Logger
  def start_link(opts, fun) do
    init(opts, fun)
  end

  def init(%{uri: uri, queue: queue, queue_error: queue_error, exchange: exchange}, fun) do
    {:ok, conn} = AMQP.Connection.open(uri)
    true = link_connection(conn)
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Queue.declare(chan, queue_error, durable: true)
    AMQP.Queue.declare(chan, queue, durable: true,
      arguments: [{"x-dead-letter-exchange", :longstr, ""},
        {"x-dead-letter-routing-key", :longstr, queue_error}])
    AMQP.Exchange.fanout(chan, exchange, durable: true)
    AMQP.Queue.bind chan, queue, exchange

    consume(chan, queue, fun)
    {:ok, self}
  end

  def link_connection(conn) do
    %AMQP.Connection{pid: pid} = conn
    Process.link(pid)
  end

  def consume(channel, queue, fun) do
    consumer_pid = spawn fn -> do_start_consumer(channel, fun) end
    AMQP.Basic.consume(channel, queue, consumer_pid)
  end

  defp do_start_consumer(channel, fun) do
    receive do
      {:basic_consume_ok, %{consumer_tag: consumer_tag}} ->
        do_consume(channel, fun, consumer_tag)
    end
  end

  defp do_consume(channel, fun, consumer_tag) do
    receive do
      {:basic_deliver, payload, %{delivery_tag: delivery_tag} = meta} ->
        try do
          Logger.debug "Consuming payload: '#{inspect payload}'"
          fun.(payload, meta)
          AMQP.Basic.ack(channel, delivery_tag)
        rescue
          exception ->
            stacktrace = System.stacktrace
            Logger.error("#{inspect exception} #{inspect stacktrace}")
            AMQP.Basic.reject(channel, delivery_tag, requeue: false)
        end
        do_consume(channel, fun, consumer_tag)
      {:basic_cancel, %{consumer_tag: ^consumer_tag, no_wait: _}} ->
        exit(:basic_cancel)
      {:basic_cancel_ok, %{consumer_tag: ^consumer_tag}} ->
        exit(:normal)
    end
  end
end
