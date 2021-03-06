defmodule Arbit.Display.Coinbasezebpay do
  @moduledoc """
    This module is responsible for
    defining the model schema and
    computing arbitrage between Coinbase & Zebpay
  """

  use Ecto.Schema
  alias Arbit.Track
  alias __MODULE__

  schema "coinbasezebpay" do
    field :coin,             :string
    field :coinbase_quote,   :string
    field :zebpay_quote,     :string
    field :coinbase_price,   :float
    field :zebpay_bid_price, :float
    field :zebpay_ask_price, :float
    field :bid_difference,   :float
    field :ask_difference,   :float
    field :zebpay_volume,    :float

    timestamps()
  end

  @doc """
  Compute arbitrage between Coinbase & Zebpay
  & return a list of %Coinbasezebpay{} structs
  """
  def compute_arbitrage do
    compute_arbitrage_usd_inr() ++ compute_arbitrage_usdc_inr()
  end

  @doc """
  Compute arbitrage between Coinbase USD coins & Zebpay INR coins
  and return a list of %Coinbasezebpay{} structs
  """
  def compute_arbitrage_usd_inr() do
    # Get Coinbase & Zebpay portfolios
    coinbase_portfolio = Track.list_coinbase()
    zebpay_portfolio   = Track.list_zebpay()

    # Filter in the coins belonging to the relevant market
    coinbase_portfolio = filter_market(coinbase_portfolio, "USD")
    zebpay_portfolio   = filter_market(zebpay_portfolio, "INR")

    # Filter in common coins in the two portfolios
    coinbase_portfolio = filter_common_coins(coinbase_portfolio, zebpay_portfolio)
    zebpay_portfolio   = filter_common_coins(zebpay_portfolio, coinbase_portfolio)

    # Sort each portfolio by coin name
    coinbase_portfolio = Enum.sort_by(coinbase_portfolio, &(&1.coin))
    zebpay_portfolio   = Enum.sort_by(zebpay_portfolio,   &(&1.coin))

    # Zip the two portfolios
    zipped_portfolios = Enum.zip(coinbase_portfolio, zebpay_portfolio)

    # Create %Coinbasezebpay{} struct with difference %
    Enum.map(zipped_portfolios, & create_coinbasezebpay_struct(&1))
  end

  @doc """
  Compute arbitrage between Coinbase USDC coins & Zebpay INR coins
  and return a list of %Coinbasezebpay{} structs
  """
  def compute_arbitrage_usdc_inr() do
    # Get Coinbase & Zebpay portfolios
    coinbase_portfolio = Track.list_coinbase()
    zebpay_portfolio   = Track.list_zebpay()

    # Filter in the coins belonging to the relevant market
    coinbase_portfolio = filter_market(coinbase_portfolio, "USDC")
    zebpay_portfolio   = filter_market(zebpay_portfolio, "INR")

    # Filter in common coins in the two portfolios
    coinbase_portfolio = filter_common_coins(coinbase_portfolio, zebpay_portfolio)
    zebpay_portfolio   = filter_common_coins(zebpay_portfolio, coinbase_portfolio)

    # Sort each portfolio by coin name
    coinbase_portfolio = Enum.sort_by(coinbase_portfolio, &(&1.coin))
    zebpay_portfolio   = Enum.sort_by(zebpay_portfolio,   &(&1.coin))

    # Zip the two portfolios
    zipped_portfolios = Enum.zip(coinbase_portfolio, zebpay_portfolio)

    # Create %Coinbasezebpay{} struct with difference %
    Enum.map(zipped_portfolios, & create_coinbasezebpay_struct(&1))
  end

  #-------------------#
  # Private Functions #
  #-------------------#

  defp filter_market(portfolio, currency) do
    Enum.filter(portfolio, fn %{quote_currency: quote_currency} -> quote_currency == currency end)
  end

  # Keep those coins in first portfolio that is also present in second portfolio
  defp filter_common_coins(first_portfolio, second_portfolio) do
    Enum.filter(first_portfolio, fn %{coin: coin} -> coin_present_in?(coin, second_portfolio) end)
  end

  defp coin_present_in?(coin, portfolio) do
    Enum.any?(portfolio, fn %{coin: coin_in_struct} -> coin == coin_in_struct end)
  end

  # Create %Coinbasezebpay{} struct and fills them
  defp create_coinbasezebpay_struct({coinbase_portfolio, zebpay_portfolio}) do
    %Coinbasezebpay{}
    |> struct(%{coin:             coinbase_portfolio.coin})
    |> struct(%{coinbase_quote:   coinbase_portfolio.quote_currency})
    |> struct(%{zebpay_quote:     zebpay_portfolio.quote_currency})
    |> struct(%{coinbase_price:   coinbase_portfolio.price_usd})
    |> struct(%{zebpay_bid_price: zebpay_portfolio.bid_price_inr})
    |> struct(%{bid_difference:   compute_difference(coinbase_portfolio.price_inr, zebpay_portfolio.bid_price_inr)})
    |> struct(%{zebpay_ask_price: zebpay_portfolio.ask_price_inr})
    |> struct(%{ask_difference:   compute_difference(coinbase_portfolio.price_inr, zebpay_portfolio.ask_price_inr)})
    |> struct(%{zebpay_volume:    zebpay_portfolio.volume})
  end

  # Compute difference %
  defp compute_difference(price1, price2) do
    (price2 - price1) / price1 * 100 |> Float.round(2)
  end
end
