## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.

defmodule ListChannelsCommandTest do
  use ExUnit.Case, async: false
  import TestHelper

  @user "guest"
  @default_timeout :infinity

  setup_all do
    :net_kernel.start([:rabbitmqctl, :shortnames])
    :net_kernel.connect_node(get_rabbit_hostname)

    close_all_connections(get_rabbit_hostname)

    on_exit([], fn ->
      close_all_connections(get_rabbit_hostname)
      :erlang.disconnect_node(get_rabbit_hostname)
      :net_kernel.stop()
    end)

    :ok
  end

  setup context do
    {
      :ok,
      opts: %{
        node: get_rabbit_hostname,
        timeout: context[:test_timeout] || @default_timeout
      }
    }
  end

  test "merge_defaults: default channel info keys are pid, user, consumer_count, and messages_unacknowledged", context do
    assert match?({~w(pid user consumer_count messages_unacknowledged), _}, ListChannelsCommand.merge_defaults([], context[:opts]))
  end

  test "validate: returns bad_info_key on a single bad arg", context do
    assert ListChannelsCommand.validate(["quack"], context[:opts]) ==
      {:validation_failure, {:bad_info_key, [:quack]}}
  end

  test "validate: returns multiple bad args return a list of bad info key values", context do
    assert ListChannelsCommand.validate(["quack", "oink"], context[:opts]) ==
      {:validation_failure, {:bad_info_key, [:quack, :oink]}}
  end

  test "validate: returns bad_info_key on mix of good and bad args", context do
    assert ListChannelsCommand.validate(["quack", "pid"], context[:opts]) ==
      {:validation_failure, {:bad_info_key, [:quack]}}
    assert ListChannelsCommand.validate(["user", "oink"], context[:opts]) ==
      {:validation_failure, {:bad_info_key, [:oink]}}
    assert ListChannelsCommand.validate(["user", "oink", "pid"], context[:opts]) ==
      {:validation_failure, {:bad_info_key, [:oink]}}
  end

  @tag test_timeout: 0
  test "run: zero timeout causes command to return badrpc", context do
    assert run_command_to_list(ListChannelsCommand, [["user"], context[:opts]]) ==
      [{:badrpc, {:timeout, 0.0}}]
  end

  test "run: multiple channels on multiple connections", context do
    close_all_connections(get_rabbit_hostname)
    with_channel("/", fn(_channel1) ->
      with_channel("/", fn(_channel2) ->
        channels = run_command_to_list(ListChannelsCommand, [["pid", "user", "connection"], context[:opts]])
        chan1 = Enum.at(channels, 0)
        chan2 = Enum.at(channels, 1)
        assert Keyword.keys(chan1) == ~w(pid user connection)a
        assert Keyword.keys(chan2) == ~w(pid user connection)a
        assert "guest" == chan1[:user]
        assert "guest" == chan2[:user]
        assert chan1[:pid] !== chan2[:pid]
      end)
    end)
  end

  test "run: multiple channels on single connection", context do
    close_all_connections(get_rabbit_hostname)
    with_connection("/", fn(conn) ->
      {:ok, _} = AMQP.Channel.open(conn)
      {:ok, _} = AMQP.Channel.open(conn)
      channels = run_command_to_list(ListChannelsCommand, [["pid", "user", "connection"], context[:opts]])
      chan1 = Enum.at(channels, 0)
      chan2 = Enum.at(channels, 1)                                          
      assert Keyword.keys(chan1) == ~w(pid user connection)a
      assert Keyword.keys(chan2) == ~w(pid user connection)a
      assert "guest" == chan1[:user]
      assert "guest" == chan2[:user]
      assert chan1[:pid] !== chan2[:pid]
    end)
  end

  test "run: info keys order is preserved", context do
    close_all_connections(get_rabbit_hostname)
    with_channel("/", fn(_channel) ->
      channels = run_command_to_list(ListChannelsCommand, [~w(connection vhost name pid number user), context[:opts]])
      chan     = Enum.at(channels, 0)
      assert Keyword.keys(chan) == ~w(connection vhost name pid number user)a
    end)
  end
end