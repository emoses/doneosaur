defmodule DoneosaurWeb.PageController do
  use DoneosaurWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
