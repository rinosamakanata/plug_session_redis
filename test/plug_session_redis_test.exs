defmodule PlugSessionRedisTest do
  use ExUnit.Case
  use Plug.Test
  alias PlugSessionRedis.RubyEncoder

  defmodule SampleApp do
    use Plug.Builder

    plug(
      Plug.Session,
      store: PlugSessionRedis.Store,
      key: "_my_app_key",
      table: Application.get_env(:plug_session_redis, :config)[:name]
    )

    plug(:fetch_session)
    plug(:add)
    plug(:destroy)
    plug(:endpoint)

    def add(%Plug.Conn{request_path: "/add"} = conn, _opts) do
      conn |> put_session(:data, :value)
    end

    def add(conn, _opts), do: conn

    def destroy(%Plug.Conn{request_path: "/destroy"} = conn, _opts) do
      conn |> configure_session(drop: true)
    end

    def destroy(conn, _opts), do: conn

    def endpoint(conn, _opts) do
      conn
      |> assign(:session, conn.private.plug_session)
      |> resp(200, "OK")
    end
  end

  test "extract user id with new line character" do
    [
      %{char: "\x03\xfb\x0Ak", user_id: 7_015_163},
      %{char: "\x03\xfb\nk", user_id: 7_015_163},
      %{char: "\x03\xfb\rk", user_id: 7_015_931},
      %{char: "\x03\xfb\x0a\x6b", user_id: 7_015_163},
      %{char: "\x03\xfb\x00\x6b", user_id: 7_012_603},
      %{char: "\x03\xfb\x0d\x6b", user_id: 7_015_931}
    ]
    |> Enum.each(fn %{char: char, user_id: user_id} ->
      assert %{"ra9api" => %{user_id: user_id}} ==
               RubyEncoder.decode!(
                 "\x04\b{\x06I\"\x0bra9api\x06:\x06EF{\a:\x0cuser_idi#{char}:\x11session_type:\nlogin"
               )
    end)

    # @poolboy_name Application.get_env(:plug_session_redis, :config)[:name]

    # test "creates a new session" do
    #   conn = conn(:get, "/foo") |> SampleApp.call([])
    #   assert %{} == conn.assigns[:session]
    # end

    # test "fetches an existing session" do
    #   :poolboy.transaction(@poolboy_name, &( :redo.cmd(&1, ["SET", "123", BinaryEncoder.encode!(%{key: :value})]) ))
    #   conn = conn(:get, "/foo") |> Plug.Conn.put_resp_cookie("_my_app_key", "123") |> SampleApp.call([])
    #   assert %{key: :value} == conn.assigns[:session]
    # end

    # test "updates an existing session" do
    #   :poolboy.transaction(@poolboy_name, &( :redo.cmd(&1, ["SET", "456", BinaryEncoder.encode!(%{key: :value})]) ))
    #   conn = conn(:get, "/add") |> Plug.Conn.put_resp_cookie("_my_app_key", "456") |> SampleApp.call([])
    #   assert %{"data" => :value} = conn.assigns[:session]
    # end

    # test "deletes an existing session" do
    #   :poolboy.transaction(@poolboy_name, &( :redo.cmd(&1, ["SET", "789", BinaryEncoder.encode!(%{key: :value})]) ))
    #   conn = conn(:get, "/destroy") |> Plug.Conn.put_resp_cookie("_my_app_key", "789") |> SampleApp.call([])
    #   Plug.Conn.send_resp(conn) # executes before send which removes session
    #   session = :poolboy.transaction(@poolboy_name, &( :redo.cmd(&1, ["GET", "789"]) ))
    #   assert session == :undefined
    # end
  end
end
