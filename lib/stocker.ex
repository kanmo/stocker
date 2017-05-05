use Mix.Config

defmodule Stocker do
  require Logger
  use Timex

  @moduledoc """
  Documentation for Stocker.
  """

  def start(_type, _args) do
    Stocker.Supervisor.start_link(:ok)
  end

  def read_ticker_codes do
    File.stream!("ticker_code_2000.csv")
    |> Enum.map(fn line ->
      String.split(line, ",") |> Enum.at(1)
    end)
  end

  def main do
    Application.get_env(:stocker, :master_node)
    |> Node.start

    Application.get_env(:stocker, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    {timestamp, _} = Duration.measure(fn -> do_requests([node|Node.list]) end)
    IO.puts "Total request completed in: #{Duration.to_milliseconds(timestamp)} "
  end

  defp do_requests(nodes) do
    ticker_codes = read_ticker_codes
    total_nodes = Enum.count(nodes)
    req_per_node = div(Enum.count(ticker_codes), total_nodes)
    code_per_node = Enum.chunk(ticker_codes, req_per_node, req_per_node, [])

    Enum.zip(nodes, code_per_node)
    |> Enum.flat_map(fn {node, codes} ->
      Enum.map(codes, fn code ->
        Task.Supervisor.async({Stocker.TasksSupervisor, node},
          Stocker.Worker, :start, [String.to_integer(code)])
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> print_results
  end

  defp print_results(results) do
    {successes, _failures} =
      results |> Enum.partition(fn x ->
      case x do
        {:ok, _} -> true
        _ -> false
      end
    end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    data = successes |> Enum.map(fn {:ok, stock_info} -> stock_info end)
    Enum.each(data, fn data ->
      IO.puts """
      name: #{data[:name]}
      recent_high_price: #{data[:recent_high_price]}
      recent_low_price: #{data[:recent_low_price]}
      high_price: #{data[:high_price]}
      low_price: #{data[:low_price]}
      price: #{data[:price]}

      """
    end)

    IO.puts """
      Total workers      : #{total_workers}
      Successful reqs    : #{total_success}
      Failed res         : #{total_failure}
      """
  end
end
