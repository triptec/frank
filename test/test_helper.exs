defmodule FrankTestUtil do

  def mq_host do
    '192.168.99.100'
  end

  def mq_port do
    5672
  end

  def mq_uri(host, port) do
    "amqp://guest:guest@#{host}:#{port}"
  end
end

ExUnit.start()
