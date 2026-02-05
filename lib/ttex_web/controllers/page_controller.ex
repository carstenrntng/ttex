defmodule TtexWeb.PageController do
  use TtexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
