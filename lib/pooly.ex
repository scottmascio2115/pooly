defmodule Pooly do
  use Application
  # Pooly.Supervisor - watches pooly.sever and pooly.workersupervisor
  # Pooly.Server - brains, tells how many workers to start
  # Pooly.WorkerSupervisor - Supervises workers
  # Pooly.worker - do work

  def start(_type, _args) do
    # Adds suport for multiple pools
    pools_config =
      [
        [name: "Pool1",
          mfa: {SampleWorker, :start_link, []}, size: 2],
        [name: "Pool2",
          mfa: {SampleWorker, :start_link, []}, size: 3],
        [name: "Pool3",
          mfa: {SampleWorker, :start_link, []}, size: 4],
      ]
    start_pool(pools_config)
  end

  def start_pools(pool_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  def checkout(pool_name) do
    Pooly.Server.checkout(pool_name)
  end

  def checkin(pool_name, worker_pid) do
    Pooly.Server.checkin(pool_name, worker_pid)
  end

  def status(pool_name) do
    Pooly.Server.status(pool_name)
  end

end

# This file specifies that this is an OTP application which serves
# as an entry point to Pooly. It contains all the conveneince funtions

# When pooly is initialized start/2 is called.
# You predefine pool_config and you call start_pool/1
