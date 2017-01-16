defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec

  # struct to maintain the state of the server
  defmodule State do
    defstruct sup: nil, worker_sup: nil, monitors: nil, size: nil, workers: nil, mfa: nil
  end

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker_pid) do
    GenServer.cast(__MODULE__, {:checkin, worker_pid})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  #############
  # Callbacks #
  #############

  # callback invoked when GenServer.start_link is called
  # stores monitors in ets table
  def init([sup, pool_config]) when is_pid(sup) do
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
  end

  # pattern match for the mfa option; Stores it in server state
  def init([{:mfa, mfa}|rest], state) do
    init(rest,  %{state | mfa: mfa})
  end

  # pattern match for the size option; Stores it in server state
  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end

  # ignore all other options
  def init([_|rest], state) do
    init(rest, state)
  end

  # base case when the options list is empty
  # send message to start the worker supervisor
  # when the server process sends a message to itself
  # the message is handled using handle info
  def init([], state) do
    send(self, :start_worker_supervisor)
    {:ok, state}
  end

  # checking out a worker means requesting and getting a worker from the pool
  # use ets table to store the monitors
  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  # Once a consumer process is done with the worker,
  # the process must return it to the pool, also known as checking in the worker.
  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid|workers]}}
      [] ->
        {:noreply, state}
    end
  end

  # Starts the worker supervisor process via the top level supervisor
  # Creates "size" number of workers that are supervised with the newly created Supervisor
  # Updates the state with the worker supervisor pid and its supervised workers
  # A supervisor must be started since it is process
  # def handle_info(:start_worker_supervisor, state = %{sup: sup, mfa: mfa, size: size}) do
  #   {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))
  #   workers = prepopulate(size, worker_sup)
  #   {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  # end
  def handle_info(:start_worker_supervisor, state = %{sup: sup, mfa: mfa, size: size}) do
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  #####################
  # Private Functions #
  #####################

  # Creates a list of workers attached to the worker supervisor
  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end

  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, sup, workers) do
    prepopulate(size-1, sup, [new_worker(sup) | workers])
  end

  # Dynamically creates a worker process and attaches it to the supervisor
  defp new_worker(sup) do
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    worker
  end

  # specifies that the process to be specified is a supervisor instead of a worker
  defp supervisor_spec(mfa) do
    opts = [restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [mfa], opts)
  end
end

# The purpose of this server is to communicate with both the
# top level supervisor and the worker Supervisor.

# Example pool configuration:
# [mfa: {SampleWorker, :start_link, []}, size: 5]
