defmodule Frank do
  require Logger
  def subscribe(uri, queue, fun) do
    {:ok, connection_manager_pid} = Frank.Connection.start_link(uri)
    chan = Frank.Connection.channel(connection_manager_pid)
    AMQP.Queue.declare chan, queue
    Frank.Subscriber.consume(chan, queue, fun)
    {:ok, connection_manager_pid}
  end

  def publish(uri, routing_key, payload) when is_binary(uri) do
    name = String.to_atom(uri)
    pid = Process.whereis(name)
    if pid do
      case Process.alive?(pid) do
        true ->
          chan = Frank.Connection.channel(name)
          publish(chan, "", routing_key, payload)
        false ->
          connect_and_publish(uri, routing_key, payload)
      end
    else
      connect_and_publish(uri, routing_key, payload)
    end
  end

  defp publish(chan, exchange, routing_key, payload, opts \\ []) do
    Frank.Publisher.publish(chan, "", routing_key, payload, opts)
  end

  defp connect_and_publish(uri, routing_key, payload) do
    name = String.to_atom(uri)
    {:ok, _} = Frank.Connection.start_link(uri, name: name)
    chan = Frank.Connection.channel(name)
    publish(chan, "", routing_key, payload)
  end
end

defmodule Frank.Publisher do
  def publish(chan, exchange, routing_key, payload, opts) do
    AMQP.Basic.publish chan, exchange, routing_key, payload, opts
  end
end

defmodule Frank.Subscriber do
  require Logger
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
