defmodule Pooly do
  use Application
  # Pooly.Supervisor - watches pooly.sever and pooly.workersupervisor
  # Pooly.Server - brains, tells how many workers to start
  # Pooly.WorkerSupervisor - Supervises workers
  # Pooly.worker - do work

  def start(_type, _args) do
    pool_config = [mfa: {SampleWorker, :start_link, []}, size: 5]
    start_pool(pool_config)
  end

  def start_pool(pool_config) do
    Pooly.Supervisor.start_link(pool_config)
  end

  def checkout do
    Pooly.Server.checkout
  end

  def checkin(worker_pid) do
    Pooly.Server.checkin(worker_pid)
  end

  def status do
    Pooly.Server.status
  end

end

# This file specifies that this is an OTP application which serves
# as an entry point to Pooly. It contains all the conveneince funtions

# When pooly is initialized start/2 is called.
# You predefine pool_config and you call start_pool/1
