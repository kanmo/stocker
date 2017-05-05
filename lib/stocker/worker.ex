defmodule Stocker.Worker do
  require Logger

  def start(code) do
    IO.puts "Runnning on node-#{node}, target ticker_code: #{code}"
    fetch_detail_info("https://stocks.finance.yahoo.co.jp/stocks/detail/?code=#{code}")
  end

  defp fetch_detail_info(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->

        name = Floki.find(body, "fortAddPortfolio, h1") |> Floki.text

        recent_high_price =
          case Floki.find(body, ".chartFinance, div dl dd strong") |> Enum.at(12) do
            nil -> "---"
            elm -> Floki.text(elm)
          end

        recent_low_price =
          case Floki.find(body, ".chartFinance, div dl dd strong") |> Enum.at(13) do
            nil -> "---"
            elm -> Floki.text(elm)
          end

        high_price =
          case Floki.find(body, ".innerDate, div dl dd strong") |> Enum.at(3) do
            nil -> "---"
            elm -> Floki.text(elm)
          end

        low_price =
          case Floki.find(body, ".innerDate, div dl dd strong") |> Enum.at(4) do
            nil -> "---"
            elm -> Floki.text(elm)
          end

        price =
          case Floki.find(body, ".stoksPrice") do
            nil -> "---"
            elm -> Floki.text(elm)
          end

        {:ok, %{name: name, recent_high_price: recent_high_price,
                recent_low_price: recent_low_price,  high_price: high_price,
                low_price: low_price, price: price }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
