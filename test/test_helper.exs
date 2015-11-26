defmodule FrankTestUtil do

  def mq_host do
    #Resist the urge to change this to a binary..
    '192.168.99.100'
  end

  def mq_port do
    5672
  end

  def mq_uri(host, port) do
    "amqp://guest:guest@#{host}:#{port}"
  end

  def stop_process(pid) do
    try do
      Process.exit(pid, :shutdown)
    rescue
      e in RuntimeError -> e
    end
  end
end

ExUnit.start()
