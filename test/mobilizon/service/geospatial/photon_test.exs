defmodule Mobilizon.Service.Geospatial.PhotonTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase, async: false

  import Mock

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Photon
  alias Mobilizon.Config

  @httpoison_headers [
    {"User-Agent",
     "#{Config.instance_name()} #{Config.instance_hostname()} - Mobilizon #{
       Mix.Project.config()[:version]
     }"}
  ]

  describe "search address" do
    test "produces a valid search address with options" do
      with_mock HTTPoison,
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "{\"features\": []"}}
        end do
        Photon.search("10 Rue Jangot",
          limit: 5,
          lang: "fr"
        )

        assert_called(
          HTTPoison.get(
            "https://photon.komoot.de/api/?q=10%20Rue%20Jangot&lang=fr&limit=5",
            @httpoison_headers
          )
        )
      end
    end

    test "returns a valid address from search" do
      use_cassette "geospatial/photon/search" do
        assert %Address{
                 locality: "Lyon",
                 description: "10 Rue Jangot",
                 region: "Auvergne-Rhône-Alpes",
                 country: "France",
                 postal_code: "69007",
                 street: "10 Rue Jangot",
                 geom: %Geo.Point{
                   coordinates: {4.8425657, 45.7517141},
                   properties: %{},
                   srid: 4326
                 }
               } == Photon.search("10 rue Jangot") |> hd
      end
    end

    # Photon returns something quite wrong, so no need to test this right now.
    #    test "returns a valid address from reverse geocode" do
    #      use_cassette "geospatial/photon/geocode" do
    #        assert %Address{
    #                 locality: "Lyon",
    #                 description: "",
    #                 region: "Auvergne-Rhône-Alpes",
    #                 country: "France",
    #                 postal_code: "69007",
    #                 street: "10 Rue Jangot",
    #                 geom: %Geo.Point{
    #                   coordinates: {4.8425657, 45.7517141},
    #                   properties: %{},
    #                   srid: 4326
    #                 }
    #               } ==
    #                 Photon.geocode(4.8425657, 45.7517141)
    #                 |> hd
    #      end
    #    end
  end
end
