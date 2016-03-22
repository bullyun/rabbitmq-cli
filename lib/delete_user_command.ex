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


defmodule DeleteUserCommand do

  def delete_user([], _) do
    HelpCommand.help
    {:bad_argument, []}
  end

  def delete_user([_|rest], _) when length(rest) != 0 do
    HelpCommand.help
    {:bad_argument, rest}
  end

  def delete_user([username], %{node: node_name}) do
    :rabbit_misc.rpc_call(
      node_name,
      :rabbit_auth_backend_internal,
      :delete_user,
      [username]
    )
  end

  def usage, do: "delete_user <username>"
end

