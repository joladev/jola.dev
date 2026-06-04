defmodule JolaDev.Atproto.Client do
  @moduledoc """
  Atproto client with basic functionality to records to standard.site
  """

  alias JolaDev.Atproto.Document
  alias JolaDev.Atproto.Publication

  @base "https://bsky.social/xrpc"

  @doc """
  Used to resolve a `did` from a handle. Handles a mutable, `did`s are permanent.
  Only need to use this once to get the `did` and can then hardcode.
  """
  def resolve_handle(handle) do
    result =
      Req.get("#{@base}/com.atproto.identity.resolveHandle",
        params: [handle: handle]
      )

    case result do
      {:ok, %Req.Response{status: 200, body: %{"did" => did}}} -> {:ok, did}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:atproto_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Used to turn an identifier and password into an access token.
  """
  def login(identifier, password) do
    result =
      Req.post("#{@base}/com.atproto.server.createSession",
        body: JSON.encode!(%{identifier: identifier, password: password}),
        headers: [{"Content-Type", "application/json"}]
      )

    case result do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"did" => did, "accessJwt" => access_token, "refreshJwt" => refresh_token}
       }} ->
        {:ok, %{did: did, access_token: access_token, refresh_token: refresh_token}}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:atproto_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Used to create a `site.standard.publication` record, aka a site record.

  We only need to do this once.
  """
  def create_publication(session, %Publication{} = publication) do
    with {:ok, icon} <- upload_blob(session, publication.icon) do
      record = publication_record(publication, icon)
      put_record(session, "site.standard.publication", "self", record)
    end
  end

  @doc """
  Used to create a `site.standard.document` record, aka a blog post record.
  """
  def publish_document(session, %Document{} = document) do
    with {:ok, cover_image} <- upload_blob(session, document.cover_image) do
      record = document_record(document, cover_image)
      put_record(session, "site.standard.document", document.rkey, record)
    end
  end

  defp publication_record(%Publication{} = publication, icon) do
    %{
      "$type" => "site.standard.publication",
      "name" => publication.name,
      "url" => publication.url,
      "description" => publication.description,
      "icon" => icon
    }
  end

  defp document_record(%Document{} = document, cover_image) do
    %{
      "$type" => "site.standard.document",
      "site" => document.site,
      "title" => document.title,
      "path" => document.path,
      "publishedAt" => to_rfc3339(document.published_at),
      "updatedAt" => to_rfc3339(document.updated_at),
      "description" => document.description,
      "textContent" => document.text_content,
      "tags" => document.tags,
      "coverImage" => cover_image
    }
  end

  defp put_record(session, collection, rkey, record) do
    headers = [
      {"Authorization", "Bearer #{session.access_token}"},
      {"Content-Type", "application/json"}
    ]

    body = JSON.encode!(%{repo: session.did, collection: collection, rkey: rkey, record: record})
    result = Req.post("#{@base}/com.atproto.repo.putRecord", body: body, headers: headers)

    case result do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:atproto_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp upload_blob(_session, nil), do: {:ok, nil}

  defp upload_blob(session, {bytes, content_type}) do
    headers = [
      {"Authorization", "Bearer #{session.access_token}"},
      {"Content-Type", content_type}
    ]

    case Req.post("#{@base}/com.atproto.repo.uploadBlob", headers: headers, body: bytes) do
      {:ok, %Req.Response{status: 200, body: %{"blob" => blob}}} -> {:ok, blob}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:atproto_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp to_rfc3339(nil), do: nil
  defp to_rfc3339(%Date{} = date), do: to_rfc3339(DateTime.new!(date, ~T[00:00:00], "Etc/UTC"))
  defp to_rfc3339(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end
