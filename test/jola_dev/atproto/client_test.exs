defmodule JolaDev.Atproto.ClientTest do
  use ExUnit.Case, async: true
  use Mimic

  alias JolaDev.Atproto.Client
  alias JolaDev.Atproto.Document

  describe "publish_document/2" do
    test "uploads the cover blob then puts the document record" do
      session = %{did: "did:plc:test", access_token: "tok", refresh_token: "ref"}

      blob = <<1, 2, 3>>
      rkey = "my-post"

      expected_uri = "at://did:plc:test/site.standard.document/#{rkey}"

      document = %Document{
        rkey: rkey,
        site: "at://did:plc:test/site.standard.publication/tid",
        title: "My Post",
        path: "/posts/my-post",
        published_at: ~D[2026-04-02],
        updated_at: ~D[2026-04-02],
        description: "desc",
        text_content: "## body",
        tags: ["elixir"],
        cover_image: {blob, "image/png"}
      }

      expect(Req, :post, 1, fn "https://bsky.social/xrpc/com.atproto.repo.uploadBlob", opts ->
        assert opts[:body] == blob
        {:ok, %Req.Response{status: 200, body: %{"blob" => %{"$type" => "blob"}}}}
      end)

      expect(Req, :post, 1, fn "https://bsky.social/xrpc/com.atproto.repo.putRecord", opts ->
        record = JSON.decode!(opts[:body])
        assert record["rkey"] == rkey
        assert record["collection"] == "site.standard.document"
        assert record["rkey"] == "my-post"
        assert record["record"]["$type"] == "site.standard.document"
        assert record["record"]["publishedAt"] == "2026-04-02T00:00:00Z"
        assert record["record"]["coverImage"] == %{"$type" => "blob"}
        assert record["record"]["textContent"] == "## body"
        {:ok, %Req.Response{status: 200, body: %{"uri" => expected_uri, "cid" => "x"}}}
      end)

      assert {:ok, %{"uri" => ^expected_uri}} = Client.publish_document(session, document)
    end
  end
end
