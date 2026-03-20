defmodule Ttex.CityMap do
  @moduledoc """
  Central map configuration for the simulation world.

  Keeps world dimensions and fixed stop positions in one place so the
  simulation, rendering, and entity spawning use the same source of truth.
  """

  @grid_rows 100
  @grid_cols 100
  @min_stop_distance 5

  @bus_stops [
    {6, 9},
    {17, 4},
    {29, 11},
    {43, 7},
    {58, 13},
    {71, 6},
    {84, 10},
    {93, 18},
    {9, 23},
    {21, 31},
    {34, 24},
    {47, 30},
    {62, 26},
    {75, 33},
    {88, 27},
    {4, 39},
    {16, 46},
    {30, 40},
    {42, 48},
    {56, 41},
    {69, 47},
    {82, 39},
    {94, 45},
    {11, 57},
    {24, 63},
    {37, 56},
    {50, 62},
    {64, 58},
    {77, 65},
    {90, 59},
    {7, 72},
    {19, 80},
    {33, 74},
    {46, 81},
    {60, 76},
    {73, 83},
    {86, 78},
    {95, 88},
    {14, 92},
    {28, 90}
  ]

  @spec grid_dimensions() :: {pos_integer(), pos_integer()}
  def grid_dimensions, do: {@grid_rows, @grid_cols}

  @spec grid_rows() :: pos_integer()
  def grid_rows, do: @grid_rows

  @spec grid_cols() :: pos_integer()
  def grid_cols, do: @grid_cols

  @spec bus_stops() :: [{non_neg_integer(), non_neg_integer()}]
  def bus_stops, do: @bus_stops

  @spec stop_entities() :: [map()]
  def stop_entities do
    ensure_stop_spacing!()

    @bus_stops
    |> Enum.with_index(1)
    |> Enum.map(fn {{x, y}, idx} ->
      %{id: "stop-#{idx}", x: x, y: y, type: :stop}
    end)
  end

  @spec random_position() :: {non_neg_integer(), non_neg_integer()}
  def random_position do
    {Enum.random(0..(@grid_cols - 1)), Enum.random(0..(@grid_rows - 1))}
  end

  defp ensure_stop_spacing! do
    case first_too_close_pair(@bus_stops, @min_stop_distance) do
      nil ->
        :ok

      {a, b, distance} ->
        raise "invalid bus stop layout: #{inspect(a)} and #{inspect(b)} are too close (distance=#{Float.round(distance, 3)} < #{@min_stop_distance})"
    end
  end

  defp first_too_close_pair(stops, min_distance) do
    Enum.reduce_while(stops, nil, fn stop, _acc ->
      remaining = stops -- [stop]

      case Enum.find(remaining, fn other -> euclidean(stop, other) < min_distance end) do
        nil ->
          {:cont, nil}

        other ->
          {:halt, {stop, other, euclidean(stop, other)}}
      end
    end)
  end

  defp euclidean({x1, y1}, {x2, y2}) do
    :math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
  end
end
