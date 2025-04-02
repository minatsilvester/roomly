defmodule Roomly.Rooms.Pomodoro do
  defstruct [
    :work_duration,
    :break_duration,
    :rounds,
    :current_round,
    :status,
    :remaining_time
  ]

  def new(config) do
    %__MODULE__{
      work_duration: config.work_duration * 60,
      break_duration: config.break_duration * 60,
      rounds: config.rounds,
      current_round: 0,
      status: :idle,
      remaining_time: config.work_duration * 60
    }
  end

  def start_timer(%__MODULE__{status: :idle} = pomo) do
    %{pomo | status: :work, current_round: 1, remaining_time: pomo.work_duration}
  end

  def handle_tick(%__MODULE__{status: :work, remaining_time: remaining_time} = pomo)
      when remaining_time > 0 do
    %{pomo | remaining_time: remaining_time - 1}
  end

  def handle_tick(pomo) do
    switch_timer(pomo)
  end

  def switch_timer(%__MODULE__{status: :work} = pomo) do
    %{pomo | status: :break, remaining_time: pomo.break_duration}
  end

  def switch_timer(%__MODULE__{status: :break, current_round: round, rounds: total_rounds} = pomo) do
    if round < total_rounds do
      %{pomo | status: :work, current_round: round + 1, remaining_time: pomo.work_duration}
    else
      {
        %{pomo | status: :completed}
      }
    end
  end

  def switch_timer(%__MODULE__{status: :idle} = pomo) do
    pomo
  end
end
