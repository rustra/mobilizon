# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/web_finger/web_finger.ex

defmodule Mobilizon.Service.WebFinger do
  @moduledoc """
  # WebFinger

  Performs the WebFinger requests and responses (JSON only)
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.XmlBuilder
  require Jason
  require Logger

  def host_meta do
    base_url = MobilizonWeb.Endpoint.url()

    {
      :XRD,
      %{xmlns: "http://docs.oasis-open.org/ns/xri/xrd-1.0"},
      {
        :Link,
        %{
          rel: "lrdd",
          type: "application/xrd+xml",
          template: "#{base_url}/.well-known/webfinger?resource={uri}"
        }
      }
    }
    |> XmlBuilder.to_doc()
  end

  def webfinger(resource, "JSON") do
    host = MobilizonWeb.Endpoint.host()
    regex = ~r/(acct:)?(?<name>\w+)@#{host}/

    with %{"name" => name} <- Regex.named_captures(regex, resource),
         %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      {:ok, represent_actor(actor, "JSON")}
    else
      _e ->
        case Actors.get_actor_by_url(resource) do
          {:ok, %Actor{} = actor} when not is_nil(actor) ->
            {:ok, represent_actor(actor, "JSON")}

          _e ->
            {:error, "Couldn't find actor"}
        end
    end
  end

  @spec represent_actor(Actor.t()) :: struct()
  def represent_actor(actor), do: represent_actor(actor, "JSON")

  @spec represent_actor(Actor.t(), String.t()) :: struct()
  def represent_actor(actor, "JSON") do
    %{
      "subject" => "acct:#{actor.preferred_username}@#{MobilizonWeb.Endpoint.host()}",
      "aliases" => [actor.url],
      "links" => [
        %{"rel" => "self", "type" => "application/activity+json", "href" => actor.url},
        %{
          "rel" => "https://webfinger.net/rel/profile-page/",
          "type" => "text/html",
          "href" => actor.url
        }
      ]
    }
  end

  defp webfinger_from_json(doc) do
    data =
      Enum.reduce(doc["links"], %{"subject" => doc["subject"]}, fn link, data ->
        case {link["type"], link["rel"]} do
          {"application/activity+json", "self"} ->
            Map.put(data, "url", link["href"])

          _ ->
            Logger.debug(fn ->
              "Unhandled type: #{inspect(link["type"])}"
            end)

            data
        end
      end)

    {:ok, data}
  end

  def finger(actor) do
    actor = String.trim_leading(actor, "@")

    domain =
      case String.split(actor, "@") do
        [_name, domain] ->
          domain

        _e ->
          URI.parse(actor).host
      end

    address = "http://#{domain}/.well-known/webfinger?resource=acct:#{actor}"

    Logger.debug(inspect(address))

    with false <- is_nil(domain),
         {:ok, %HTTPoison.Response{} = response} <-
           HTTPoison.get(
             address,
             [Accept: "application/json, application/activity+json, application/jrd+json"],
             follow_redirect: true
           ),
         %{status_code: status_code, body: body} when status_code in 200..299 <- response,
         {:ok, doc} <- Jason.decode(body) do
      webfinger_from_json(doc)
    else
      e ->
        Logger.debug(fn -> "Couldn't finger #{actor}" end)
        Logger.debug(fn -> inspect(e) end)
        {:error, e}
    end
  end
end
