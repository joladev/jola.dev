defmodule JolaDev.BlogTest do
  use ExUnit.Case, async: true
  alias JolaDev.Blog

  describe "all_posts/0" do
    test "returns posts sorted by descending date" do
      posts = Blog.all_posts()

      assert is_list(posts)
      assert posts != []

      # Verify posts are sorted by date in descending order
      dates = Enum.map(posts, & &1.date)
      assert dates == Enum.sort(dates, {:desc, Date})
    end
  end

  describe "all_tags/0" do
    test "returns unique sorted tags" do
      tags = Blog.all_tags()

      assert is_list(tags)
      assert tags != []
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

  describe "related_posts/2" do
    test "excludes the post itself" do
      post = List.first(Blog.all_posts())
      related = Blog.related_posts(post)

      refute Enum.any?(related, &(&1.id == post.id))
    end

    test "respects the limit argument" do
      post = List.first(Blog.all_posts())

      assert length(Blog.related_posts(post, 1)) == 1
      assert length(Blog.related_posts(post, 2)) == 2
    end

    test "defaults to 3 results when enough posts exist" do
      post = List.first(Blog.all_posts())
      related = Blog.related_posts(post)

      assert length(related) == 3
    end

    test "ranks posts sharing more tags higher than posts sharing fewer" do
      # Pick a post with multiple tags to exercise the ranking.
      post = Enum.find(Blog.all_posts(), &(length(&1.tags) >= 2))
      related = Blog.related_posts(post, 5)

      counts =
        Enum.map(related, fn p ->
          Enum.count(p.tags, &(&1 in post.tags))
        end)

      # Non-increasing — higher counts come first.
      assert counts == Enum.sort(counts, :desc)
    end

    test "falls back to latest posts when fewer than limit share tags" do
      # A post with a unique tag that no other post shares forces full fallback.
      unique = %JolaDev.Blog.Post{
        id: "synthetic-test-post",
        author: "test",
        title: "test",
        body: "",
        description: "",
        tags: ["this-tag-shares-with-nothing-#{System.unique_integer()}"],
        date: ~D[2030-01-01]
      }

      related = Blog.related_posts(unique, 3)
      latest_three = Enum.take(Blog.all_posts(), 3)

      assert related == latest_three
    end

    test "mixes tag-matches with latest fillers when partial" do
      # A post sharing only one tag with one other post should yield 1 match + 2 fillers.
      [reference | _] = Enum.filter(Blog.all_posts(), &(&1.tags != []))

      synthetic = %JolaDev.Blog.Post{
        id: "synthetic-partial-#{System.unique_integer()}",
        author: "test",
        title: "test",
        body: "",
        description: "",
        tags: [hd(reference.tags)],
        date: ~D[2030-01-01]
      }

      related = Blog.related_posts(synthetic, 3)

      assert length(related) == 3
      # The first result must share the tag.
      assert hd(reference.tags) in hd(related).tags
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
