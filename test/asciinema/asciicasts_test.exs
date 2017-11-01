defmodule Asciinema.AsciicastsTest do
  use Asciinema.DataCase
  alias Asciinema.Asciicasts
  alias Asciinema.Asciicasts.Asciicast

  describe "create_asciicast/3" do
    test "pre-v1 payload with uname" do
      user = fixture(:user)
      params = %{"meta" => %{"version" => 0,
                             "command" => "/bin/bash",
                             "duration" => 11.146430015564,
                             "shell" => "/bin/zsh",
                             "term" => %{"columns" => 96,
                                         "lines" => 26,
                                         "type" => "screen-256color"},
                             "title" => "bashing :)",
                             "uname" => "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64"},
                 "stdout" => fixture(:upload, %{path: "0.9.7/stdout",
                                                content_type: "application/octet-stream"}),
                 "stdout_timing" => fixture(:upload, %{path: "0.9.7/stdout.time",
                                                       content_type: "application/octet-stream"})}

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{version: 2,
                        file: "0.cast",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: "/bin/bash",
                        duration: 3.7037009999999997,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64",
                        user_agent: nil} = asciicast
    end

    test "pre-v1 payload without uname" do
      user = fixture(:user)
      params = %{"meta" => %{"version" => 0,
                             "command" => "/bin/bash",
                             "duration" => 11.146430015564,
                             "shell" => "/bin/zsh",
                             "term" => %{"columns" => 96,
                                         "lines" => 26,
                                         "type" => "screen-256color"},
                             "title" => "bashing :)"},
                 "stdout" => fixture(:upload, %{path: "0.9.8/stdout",
                                                content_type: "application/octet-stream"}),
                 "stdout_timing" => fixture(:upload, %{path: "0.9.8/stdout.time",
                                                       content_type: "application/octet-stream"})}

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{version: 2,
                        file: "0.cast",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: "/bin/bash",
                        duration: 3.7037009999999997,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "pre-v1 payload, utf-8 sequence split between frames" do
      user = fixture(:user)
      params = %{"meta" => %{"version" => 0,
                             "command" => "/bin/bash",
                             "duration" => 11.146430015564,
                             "shell" => "/bin/zsh",
                             "term" => %{"columns" => 96,
                                         "lines" => 26,
                                         "type" => "screen-256color"},
                             "title" => "bashing :)"},
                 "stdout" => fixture(:upload, %{path: "0.9.8/stdout-split",
                                                content_type: "application/octet-stream"}),
                 "stdout_timing" => fixture(:upload, %{path: "0.9.8/stdout-split.time",
                                                       content_type: "application/octet-stream"})}

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})
      stream = Asciicasts.stdout_stream(asciicast)

      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end

    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{version: 1,
                        file: "asciicast.json",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: "/bin/bash",
                        duration: 11.146430015564,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "json file, v1 format (missing required data)" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Asciicasts.create_asciicast(user, upload)
    end

    test "json file, unsupported version number" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, {:unsupported_format, 5}} = Asciicasts.create_asciicast(user, upload)
    end

    test "cast file, v2 format, minimal" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{version: 2,
                        terminal_columns: 96,
                        terminal_lines: 26,
                        duration: 8.456789,
                        file: "minimal.cast",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: nil,
                        recorded_at: nil,
                        shell: nil,
                        terminal_type: nil,
                        title: nil,
                        theme_fg: nil,
                        theme_bg: nil,
                        theme_palette: nil,
                        idle_time_limit: nil,
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "cast file, v2 format, full" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})
      recorded_at = Timex.from_unix(1506410422)

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{version: 2,
                        terminal_columns: 96,
                        terminal_lines: 26,
                        duration: 8.456789,
                        file: "full.cast",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: "/bin/bash -l",
                        recorded_at: ^recorded_at,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        title: "bashing :)",
                        theme_fg: "#aaaaaa",
                        theme_bg: "#bbbbbb",
                        theme_palette: "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
                        idle_time_limit: 2.5,
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "unknown file format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "new-logo-bars.png"})

      assert {:error, :unknown_format} = Asciicasts.create_asciicast(user, upload)
    end
  end

  describe "stdout_stream/1" do
    test "with asciicast v1 file" do
      stream = Asciicasts.stdout_stream("spec/fixtures/1/asciicast.json")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {6.913554, "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file" do
      stream = Asciicasts.stdout_stream("spec/fixtures/2/full.cast")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}] == Enum.take(stream, 2)
    end
  end

  describe "stdout_stream/2" do
    test "with gzipped files" do
      stream = Asciicasts.stdout_stream({"spec/fixtures/0.9.9/stdout.time",
                                         "spec/fixtures/0.9.9/stdout"})
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files" do
      stream = Asciicasts.stdout_stream({"spec/fixtures/0.9.8/stdout.time",
                                         "spec/fixtures/0.9.8/stdout"})
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files (utf-8 sequence split between frames)" do
      stream = Asciicasts.stdout_stream({"spec/fixtures/0.9.8/stdout-split.time",
                                         "spec/fixtures/0.9.8/stdout-split"})
      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end
  end

  describe "generate_snapshot/2" do
    @tag :vt
    test "returns list of screen lines" do
      stdout_stream = [{1.0, "a"}, {2.4, "b"}, {2.6, "c"}]
      snapshot = Asciicasts.generate_snapshot(stdout_stream, 4, 2, 2.5)
      assert snapshot == [[["ab  ", %{}]], [["    ", %{}]]]
    end
  end
end
