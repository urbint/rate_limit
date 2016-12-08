defmodule RateLimit.Utils do
  @compile {:inline, timestamp: 0}

  @otp_release "#{:erlang.system_info(:otp_release)}" |> Integer.parse |> elem(1)

  @moduledoc false

  @doc """
  Returns the current time as milliseconds.

  """
  case @otp_release do
    ver when ver >= 18 ->
      def timestamp(), do: :erlang.system_time(:milli_seconds)
    _ ->
      def timestamp(), do: timestamp(:erlang.now())
  end

end
