defmodule Pooly do

  # Pooly.Supervisor - watches pooly.sever and pooly.workersupervisor
  # Pooly.Server - brains, tells how many workers to start
  # Pooly.WorkerSupervisor - Supervises workers
  # Pooly.worker - do work
end
