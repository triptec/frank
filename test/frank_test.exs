defmodule FrankTest do
  use ExUnit.Case
  import FrankTestUtil
  doctest Frank

  test "publish with uri, queue and payload" do
    queue = "test"
    msg = "uri, queue and payload"
    fun = fn (payload, _meta) ->
      send :frank_test, payload
    end
    Process.register(self, :frank_test)
    {:ok, cmp} = Frank.subscribe(mq_uri(mq_host, mq_port), queue, fun)
    :ok = Frank.publish(mq_uri(mq_host, mq_port), queue, msg)
    assert_receive msg
  end

  test "publish with uri, queue and payload and have fun" do
    queue = "test"
    msg = "uri, queue and payload"
    fun = fn (payload, _meta) ->
      send :frank_test, payload
    end
    Process.register(self, :frank_test)
    {:ok, cmp} = Frank.subscribe(mq_uri(mq_host, mq_port), queue, fun)
    Enum.map(1..1000,
      fn x -> :ok = Frank.publish(mq_uri(mq_host, mq_port), queue, Integer.to_string(x)) end
    )
    assert_receive "1000", 1000
  end
end
