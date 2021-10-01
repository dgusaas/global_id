defmodule GlobalId do
  @moduledoc """
  GlobalId module contains an implementation of a guaranteed globally unique id system.

  1. Please describe your solution to get_id and why it is correct i.e. guaranteed globally unique.

  The global ID is made up of three parts, a 41 bit timestamp, the 11 bit node ID, and a 12 bit serial number.

  timestamp: Guarantees that IDs generated by the same node are unique
  node ID:   Guarantees that IDs generated by each node are unique. Note that this requires 11 bits instead of 10,
             as it is inclusive of 1024. If was 10 bits node 0 and 1024 could produce identical ids.
  serial:    Guarantees that IDs generated by the same timestamp are unique, at most 4096 to a timestamp

  Combining these together guarantees uniqueness across all nodes.

  2. Please explain how your solution achieves the desired performance i.e. 100,000 or more requests per second per node.  How did you verify this?

  Since get_id() has to do so little, just check/update the previous timestamp, form a size 64 bitstring, and finally convert it into an 
  unsigned integer, it is easily able to meet to the 100,000 per second requirement. Using https://github.com/alco/benchfella, I was able to 
  get the approximate amount of requests per second that get_id() can handle (the results are in bench\snapshots). It came out to ~500,000 
  requests per second, that is, about .2 seconds for 100,000 requests.

  3. Please enumerate possible failure cases and describe how your solution correctly handles each case.  How did you verify correctness?  Some example cases:

  Using timestamp allows nodes to effectively be stateless, meaning a nodecrash has no impact on the uniqueness of an id generated after 
  a crash. As timestamps by nature are ever incrementing, when a node restarts it will read the new timestamp and continue generating unique 
  ids. The only time where uniqueness is at risk, is if the node were to restart the exact same millisecond that it stopped. A simple way to 
  prevent this case, is to have the node sleep for a small period when it starts. For system wide uniqueness, the node ID guarantees that no 
  matter what state the system is in that IDs will continue to be unique. I verified with unit tests.
  """

  use Agent

  @doc """
  Start GlobalId's Agent
  """
  @spec start_link() :: tuple()
  def start_link do
    Agent.start_link(fn -> [timestamp(), 0] end)
  end

  @doc """
  Stop GlobalId's Agent
  """
  @spec stop(pid()) :: atom()
  def stop(agent) do
    Agent.stop(agent)
  end

  @doc """
  Get GlobalId's Agent's state, only used for testing
  """
  @spec get(pid()) :: list()
  def get(agent) do
    Agent.get(agent, fn state -> state end)
  end

  @doc """
  Get and update GlobalId's Agent's state
  """
  @spec get_and_update(pid()) :: non_neg_integer()
  def get_and_update(agent) do
    Agent.get_and_update(agent, fn state -> new_state(state) end)
  end

  @doc """
  Compare timestamps and get the id for the state,
  use serial to ensure uniqueness for ids with the same timestamp
  """
  @spec new_state(list()) :: tuple()
  def new_state(state) do
    timestamp = timestamp()
    [prev_timestamp, serial] = state
    [timestamp, serial] = cond do
                            serial === 4095 ->
                              [prev_timestamp + 1, 0]
                            timestamp === prev_timestamp ->
                              [prev_timestamp, serial + 1]
                            timestamp < prev_timestamp ->
                              [prev_timestamp, serial + 1]
                            true ->
                              [timestamp, 0]
                          end
    {get_id(timestamp, node_id(), serial), [timestamp, serial]}
  end

  @doc """
  Please implement the following function.
  64 bit non negative integer output
  """
  @spec get_id(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def get_id(timestamp, node_id, serial) do
    :binary.decode_unsigned(<<0::1, timestamp::41, node_id::10, serial::12>>)
  end

  #
  # You are given the following helper functions
  # Presume they are implemented - there is no need to implement them.
  #

  @doc """
  Returns your node id as an integer.
  It will be greater than or equal to 0 and less than or equal to 1024.
  It is guaranteed to be globally unique.
  """
  @spec node_id() :: non_neg_integer()
  def node_id do
    # 512
  end

  @doc """
  Returns timestamp since the epoch in milliseconds.
  """
  @spec timestamp() :: non_neg_integer()
  def timestamp do
    # System.monotonic_time(:millisecond)
  end
end
