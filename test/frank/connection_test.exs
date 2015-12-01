defmodule Frank.ConnectionTest do
  use ExUnit.Case
  import FrankTestUtil
  doctest Frank.Connection



  test "reconnect when connection lost" do
    Application.start(:ranch)
    flaky_conn = FlakyConnection.start(mq_host, mq_port)
    flaky_port = flaky_conn.port
    {:ok, cmp} = Frank.Connection.start_link(mq_uri("localhost", flaky_port))

    :timer.sleep 100

    conn_pid = Frank.Connection.connection_pid(cmp)

    FlakyConnection.stop(flaky_conn)

    :timer.sleep 100

    assert Process.alive?(conn_pid) == false
    # Restart Flakey connection manually, things should be back to normal
    flaky_conn = FlakyConnection.start(mq_host, mq_port, flaky_port)
    :timer.sleep 100
    conn_pid = Frank.Connection.connection_pid(cmp)
    assert Process.alive?(conn_pid) == true

    #FlakyConnection.stop(flaky_conn)
    stop_process cmp
  end

  test "continued subscription when connection lost" do
    queue = "test"
    first_msg = "continued subscription when connection lost first"
    second_msg = "continued subscription when connection lost second"
    fun = fn (payload, _meta) ->
      send :frank_test, payload
    end
    Process.register(self, :frank_test)

    Application.start(:ranch)
    flaky_conn = FlakyConnection.start(mq_host, mq_port)
    flaky_port = flaky_conn.port

    {:ok, cmp} = Frank.subscribe(mq_uri("localhost", flaky_port), queue, fun)

    #:timer.sleep 100

    :ok = Frank.publish(mq_uri(mq_host, mq_port), queue, first_msg)
    assert_receive first_msg


    conn_pid = Frank.Connection.connection_pid(cmp)
    chan_pid = Frank.Connection.channel_pid(cmp)
    assert Process.alive?(conn_pid) == true
    assert Process.alive?(chan_pid) == true

    FlakyConnection.stop(flaky_conn)

    :timer.sleep 100

    assert Process.alive?(conn_pid) == false
    assert Process.alive?(chan_pid) == false
    # Restart Flakey connection manually, things should be back to normal
    flaky_conn = FlakyConnection.start(mq_host, mq_port, flaky_port)
    :timer.sleep 100
    conn_pid = Frank.Connection.connection_pid(cmp)
    assert Process.alive?(conn_pid) == true

    :ok = Frank.publish(mq_uri(mq_host, mq_port), queue, second_msg)
    assert_receive second_msg

    #FlakyConnection.stop(flaky_conn)
    stop_process cmp
  end
end
