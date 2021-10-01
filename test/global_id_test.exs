defmodule GlobalIdTest do
  use ExUnit.Case
  doctest GlobalId

  test "id is 64 bits" do
    id = GlobalId.get_id(1632961191745, 512, 0)
    assert id === :binary.decode_unsigned(<<id::64>>)
  end

  test "uniqueness on same timestamp, one node" do
    {:ok, agent} = GlobalId.start_link()
    id0 = GlobalId.get_and_update(agent)
    id1 = GlobalId.get(agent) |> GlobalId.new_state()
    GlobalId.stop(agent)
    assert id0 !== id1
  end

  test "uniqueness on same timestamp, system wide" do
    timestamp = 1632961191745
    ids = Enum.to_list(0..1023) |> 
          Enum.map(fn node -> GlobalId.get_id(timestamp, node, 0) end) |>
          MapSet.new()
    assert MapSet.size(ids) === 1024
  end

  test "all unique, one node" do
    {:ok, agent} = GlobalId.start_link()
    ids = Enum.to_list(1..100000) |>
          Enum.map(fn _ -> GlobalId.get_and_update(agent) end) |>
          MapSet.new()
    assert MapSet.size(ids) === 100000
  end
end
