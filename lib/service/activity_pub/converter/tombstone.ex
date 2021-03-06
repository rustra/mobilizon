defmodule Mobilizon.Service.ActivityPub.Converter.Tombstone do
  @moduledoc """
  Comment converter.

  This module allows to convert Tombstone models to ActivityStreams data
  """

  alias Mobilizon.Tombstone, as: TombstoneModel
  alias Mobilizon.Service.ActivityPub.{Converter, Convertible}

  require Logger

  @behaviour Converter

  defimpl Convertible, for: TombstoneModel do
    alias Mobilizon.Service.ActivityPub.Converter.Tombstone, as: TombstoneConverter

    defdelegate model_to_as(comment), to: TombstoneConverter
  end

  @doc """
  Make an AS tombstone object from an existing `Tombstone` structure.
  """
  @impl Converter
  @spec model_to_as(TombstoneModel.t()) :: map
  def model_to_as(%TombstoneModel{} = tombstone) do
    %{
      "type" => "Tombstone",
      "id" => tombstone.uri,
      "deleted" => tombstone.inserted_at
    }
  end

  @doc """
  Converting an Tombstone to an object makes no sense, nevertheless…
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(object), do: object
end
