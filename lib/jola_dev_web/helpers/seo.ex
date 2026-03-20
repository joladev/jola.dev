defmodule JolaDevWeb.SEO do
  @moduledoc """
  Generates JSON-LD structured data for search engines and AI systems.
  """

  @host "https://jola.dev"

  def json_ld(conn) do
    [website_schema()] ++ page_schemas(conn)
  end

  defp website_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "jola.dev",
      "url" => @host,
      "author" => person_ref()
    }
  end

  defp page_schemas(%{assigns: %{post: post}}) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "BlogPosting",
        "headline" => post.title,
        "description" => post.description,
        "datePublished" => Date.to_iso8601(post.date),
        "author" => person(),
        "publisher" => person(),
        "mainEntityOfPage" => "#{@host}/posts/#{post.id}",
        "image" => "#{@host}/images/og-image.png",
        "keywords" => post.tags
      }
    ]
  end

  defp page_schemas(%{assigns: %{page_type: :about}}) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "ProfilePage",
        "mainEntity" =>
          Map.merge(person(), %{
            "sameAs" => [
              "https://github.com/joladev",
              "https://linkedin.com/in/joladev",
              "https://bsky.app/profile/jola.dev",
              "https://twitter.com/joladev"
            ]
          })
      }
    ]
  end

  defp page_schemas(_conn), do: []

  defp person do
    %{
      "@type" => "Person",
      "@id" => "#{@host}/#person",
      "name" => "Johanna Larsson",
      "url" => "#{@host}/about",
      "jobTitle" => "Software Engineer & Engineering Leader"
    }
  end

  defp person_ref do
    %{"@id" => "#{@host}/#person"}
  end
end
