defmodule Mix.Tasks.Atproto.Publish do
  @shortdoc "Publishes a blog post as a standard.site record."
  @moduledoc """
  Publishes a blog post as a standard.site record.
  """

  use Mix.Task

  alias JolaDev.Atproto
  alias JolaDev.Atproto.Client

  def run([slug]) do
    Application.ensure_all_started(:req)

    password = System.fetch_env!("PASSWORD")
    post = JolaDev.Blog.find_by_id(slug)

    {:ok, session} = Client.login("jola.dev", password)
    {:ok, result} = Client.publish_document(session, Atproto.document(post))

    Mix.shell().info("Published #{slug} as #{result["uri"]}")
  end
end
