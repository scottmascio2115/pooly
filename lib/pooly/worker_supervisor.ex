defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link({_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  def init({m, f, a} = x) do
    # Specify that the worker is always to be restarted
    # Specify the function to start the worker with f
    worker_opts = [restart: :permanent,
                   function: f]

    # creates a list of the child processes
    children = [worker(m, a, worker_opts)]

    # Specifies the options for the supervisor
    opts = [strategy: :simple_one_for_one,
            max_restarts: 5,
            max_seconds: 5]

    # herlper function to create the child specification
    supervise(children, opts)
  end
end
