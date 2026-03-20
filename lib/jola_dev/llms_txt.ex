defmodule JolaDev.LlmsTxt do
  @moduledoc """
  Generates llms.txt and llms-full.txt content per the llmstxt.org spec.
  """

  alias JolaDev.Blog

  @host "https://jola.dev"

  def generate do
    """
    # jola.dev

    > Personal website of Johanna Larsson, a software engineer, engineering leader, writer, and speaker with over 14 years of experience building products and leading teams.

    ## Pages

    - [About](#{@host}/about): Background, experience, and expertise
    - [Blog](#{@host}/posts): Technical blog posts on software engineering, Elixir, and leadership
    - [Projects](#{@host}/projects): Open source projects
    - [Talks](#{@host}/talks): Conference presentations and speaking engagements

    ## Blog Posts

    #{post_links()}\
    """
    |> String.trim_trailing()
  end

  def generate_full do
    """
    # jola.dev

    > Personal website of Johanna Larsson, a software engineer, engineering leader, writer, and speaker with over 14 years of experience building products and leading teams.

    ## Pages

    - [About](#{@host}/about): Background, experience, and expertise
    - [Blog](#{@host}/posts): Technical blog posts on software engineering, Elixir, and leadership
    - [Projects](#{@host}/projects): Open source projects
    - [Talks](#{@host}/talks): Conference presentations and speaking engagements

    ## Blog Posts

    #{post_details()}\
    """
    |> String.trim_trailing()
  end

  defp post_links do
    Blog.all_posts()
    |> Enum.map_join("\n", fn post ->
      "- [#{post.title}](#{@host}/posts/#{post.id})"
    end)
  end

  defp post_details do
    Blog.all_posts()
    |> Enum.map_join("\n", fn post ->
      "- [#{post.title}](#{@host}/posts/#{post.id}): #{post.description}"
    end)
  end
end
