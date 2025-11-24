defmodule AdhdoWeb.PageController do
  use AdhdoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
