defmodule JolaDev.BlogTest do
  use ExUnit.Case, async: true
  alias JolaDev.Blog

  describe "all_posts/0" do
    test "returns posts sorted by descending date" do
      posts = Blog.all_posts()

      assert is_list(posts)
      assert length(posts) > 0

      # Verify posts are sorted by date in descending order
      dates = Enum.map(posts, & &1.date)
      assert dates == Enum.sort(dates, {:desc, Date})
    end
  end

  describe "all_tags/0" do
    test "returns unique sorted tags" do
      tags = Blog.all_tags()

      assert is_list(tags)
      assert length(tags) > 0
      assert tags == Enum.uniq(tags)
      assert tags == Enum.sort(tags)
    end
  end

  describe "find_by_id/1" do
    test "finds post by id when exists" do
      # Get a known post ID from the list
      first_post = List.first(Blog.all_posts())
      found_post = Blog.find_by_id(first_post.id)

      assert found_post == first_post
    end

    test "returns nil when post id does not exist" do
      assert Blog.find_by_id("non-existent-id") == nil
    end
  end

  describe "titles/0" do
    test "returns list of all post titles" do
      titles = Blog.titles()
      posts = Blog.all_posts()

      assert is_list(titles)
      assert length(titles) == length(posts)
      assert titles == Enum.map(posts, & &1.title)
    end
  end

  describe "ids/0" do
    test "returns list of all post ids" do
      ids = Blog.ids()
      posts = Blog.all_posts()

      assert is_list(ids)
      assert length(ids) == length(posts)
      assert ids == Enum.map(posts, & &1.id)
    end
  end

  describe "post structure" do
    test "posts have all required fields" do
      post = List.first(Blog.all_posts())

      assert Map.has_key?(post, :id)
      assert Map.has_key?(post, :author)
      assert Map.has_key?(post, :title)
      assert Map.has_key?(post, :body)
      assert Map.has_key?(post, :description)
      assert Map.has_key?(post, :tags)
      assert Map.has_key?(post, :date)

      assert is_binary(post.id)
      assert is_binary(post.author)
      assert is_binary(post.title)
      assert is_binary(post.body)
      assert is_binary(post.description)
      assert is_list(post.tags)
      assert %Date{} = post.date
    end
  end
end
