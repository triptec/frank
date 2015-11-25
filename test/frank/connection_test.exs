defmodule Frank.ConnectionTest do
  use ExUnit.Case
  import FrankTestUtil
  doctest Frank.Connection

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "connection lost" do
    Application.start(:ranch)
    flaky_conn = FlakyConnection.start(mq_host, mq_port, 9999)
    #{:ok, conn} = Frank.Connection.open(mq_uri('localhost', flaky_conn.port))
    #pid = spawn_link(Frank.Connection, :open, [mq_uri('localhost', flaky_conn.port)])
    Frank.Connection.start_link(mq_uri('localhost', flaky_conn.port))
    #send pid, {:lol}
    :timer.sleep 1000
    FlakyConnection.stop(flaky_conn)
    #FlakyConnection.set_latency(flaky_conn, 4000)
    :timer.sleep 5000

    # Restart Flakey connection manually, things should be back to normal
    flaky_conn = FlakyConnection.start(mq_host, mq_port, 9999)

    #FlakyConnection.set_latency(flaky_conn, 0)
    :timer.sleep 5000

    #{:ok, conn} = AMQP.Connection.open(mq_uri(mq_port))
  end
end
