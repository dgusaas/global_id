defmodule GlobalIdBench do
  use Benchfella

  bench "single get_id" do
    GlobalId.get_id(1632961191745, 512, 0)
  end

  bench "at least 100,000 requests per second" do
    {:ok, agent} = GlobalId.start_link()
    Enum.to_list(1..100000) |> 
    Enum.map(fn _ -> GlobalId.get_and_update(agent) end)
    GlobalId.stop(agent)
  end
end