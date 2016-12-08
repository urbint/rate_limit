defmodule RateLimit.Engine.ETS do
  @moduledoc false

  alias RateLimit.Engine

  @behaviour Engine

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    table =
      :ets.new(:rate_limit_ets, [])

    {:ok, table}
  end

  def incr(id, count, max, expire) do
    GenServer.call(__MODULE__, {:incr, id, count, max, expire})
  end

  def handle_call({:incr, id, count, max, expire}, _caller, table) do
    reply =
      case :ets.lookup(table, id) do
        [] ->
          create_counter(table, {id, count}, expire)

        [counter] ->
          with {:ok, updated_counter} <- use_requests(counter, count, max) do
            :ets.insert(table, updated_counter)
          end
      end

    {:reply, reply, table}
  end

  defp create_counter(table, counter = {id, _}, expire) do
    :ets.insert(table, counter)
    Process.send_after(self, {:expire, id}, expire)
    :ok
  end

  defp use_requests({id, used_count}, count, max) do
    cond do
    used_count + count > max and count == 1 ->
      {:error, "Rate limit exceeded"}
    used_count + count > max and count > 1 ->
      {:error, "Using #{count} requests would exceed rate limit"}
    true ->
      {:ok, {id, used_count + count}}
    end
  end

  def handle_info({:expire, id}, table) do
    :ets.delete(table, id)
    {:noreply, table}
  end

end
