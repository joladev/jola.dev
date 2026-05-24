defmodule JolaDevWeb.Helpers.SEO do
  @moduledoc """
  Generates JSON-LD structured data for search engines and AI systems.
  """

  use JolaDevWeb, :verified_routes

  @host "https://jola.dev"

  def json_ld(conn) do
    [website_schema(), person_schema()] ++ page_schemas(conn) ++ breadcrumb_schemas(conn)
  end

  defp website_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "jola.dev",
      "url" => @host
    }
  end

  defp person_schema do
    Map.put(person(), "@context", "https://schema.org")
  end

  defp page_schemas(%{assigns: %{post: post}}) do
    url = "#{@host}#{~p"/posts/#{post.id}"}"

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "BlogPosting",
        "headline" => post.title,
        "description" => post.description,
        "datePublished" => Date.to_iso8601(post.date),
        "dateModified" => Date.to_iso8601(post.last_modified),
        "inLanguage" => "en",
        "url" => url,
        "author" => person(),
        "publisher" => person(),
        "mainEntityOfPage" => url,
        "image" => "#{@host}#{JolaDev.OGImage.path_for("posts/#{post.id}")}",
        "keywords" => post.tags
      }
    ]
  end

  defp page_schemas(%{assigns: %{page_type: :about}}) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "ProfilePage",
        "mainEntity" => person_ref()
      }
    ]
  end

  defp page_schemas(%{assigns: %{posts: _, tag: _}}), do: []

  defp page_schemas(%{assigns: %{posts: posts}}) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "Blog",
        "@id" => "#{@host}/posts#blog",
        "url" => "#{@host}/posts",
        "name" => "jola.dev blog",
        "author" => person_ref(),
        "blogPost" => Enum.map(posts, &blog_post_summary/1)
      }
    ]
  end

  defp page_schemas(_conn), do: []

  defp blog_post_summary(post) do
    url = "#{@host}#{~p"/posts/#{post.id}"}"

    %{
      "@type" => "BlogPosting",
      "headline" => post.title,
      "url" => url,
      "datePublished" => Date.to_iso8601(post.date),
      "dateModified" => Date.to_iso8601(post.last_modified),
      "image" => "#{@host}#{JolaDev.OGImage.path_for("posts/#{post.id}")}",
      "author" => person_ref()
    }
  end

  defp person do
    %{
      "@type" => "Person",
      "@id" => "#{@host}/#person",
      "name" => "Johanna Larsson",
      "url" => "#{@host}#{~p"/about"}",
      "jobTitle" => "Software Engineer & Engineering Leader",
      "sameAs" => [
        "https://github.com/joladev",
        "https://linkedin.com/in/joladev",
        "https://bsky.app/profile/jola.dev",
        "https://twitter.com/joladev"
      ]
    }
  end

  defp person_ref do
    %{"@id" => "#{@host}/#person"}
  end

  defp breadcrumb_schemas(conn) do
    case breadcrumb_items(conn) do
      items when length(items) > 1 ->
        [
          %{
            "@context" => "https://schema.org",
            "@type" => "BreadcrumbList",
            "itemListElement" =>
              items
              |> Enum.with_index(1)
              |> Enum.map(fn {{name, path}, position} ->
                %{
                  "@type" => "ListItem",
                  "position" => position,
                  "name" => name,
                  "item" => "#{@host}#{path}"
                }
              end)
          }
        ]

      _ ->
        []
    end
  end

  @home {"Home", "/"}
  @blog {"Blog", "/posts"}

  @static_crumbs %{
    "/about" => {"About", "/about"},
    "/projects" => {"Projects", "/projects"},
    "/talks" => {"Talks", "/talks"},
    "/posts" => {"Blog", "/posts"}
  }

  defp breadcrumb_items(%{assigns: %{post: post}}),
    do: [@home, @blog, {post.title, ~p"/posts/#{post.id}"}]

  defp breadcrumb_items(%{assigns: %{tag: tag}}),
    do: [@home, @blog, {tag, ~p"/posts/tag/#{tag}"}]

  defp breadcrumb_items(%{request_path: path}) do
    case Map.fetch(@static_crumbs, path) do
      {:ok, crumb} -> [@home, crumb]
      :error -> []
    end
  end
end
