defmodule Frank do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Frank.Producer
      alias Frank.Consumer
      alias Frank.Connection
    end
  end
end
