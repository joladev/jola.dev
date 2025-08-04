defmodule JolaDevWeb.RssXML do
  @moduledoc """
  Module for rendering RSS feed templates.
  """
  use JolaDevWeb, :html

  embed_templates "rss_xml/*"

  def format_rfc822(%Date{} = date) do
    date
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> format_rfc822()
  end

  def format_rfc822(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%a, %d %b %Y %H:%M:%S +0000")
  end
end
