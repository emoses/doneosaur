defmodule Doneosaur.Lists.Schedule do
  @moduledoc """
  Schema for task list schedules.
  Each schedule represents one specific time on one day of the week when a task list should be activated.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_list_schedule" do
    field :day_of_week, :integer
    field :time, :time

    belongs_to :task_list, Doneosaur.Lists.TaskList
  end

  @doc """
  Changeset for creating or updating a schedule.
  """
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:day_of_week, :time, :task_list_id])
    |> validate_required([:day_of_week, :time, :task_list_id])
    |> validate_day_of_week()
    |> foreign_key_constraint(:task_list_id)
  end

  defp validate_day_of_week(changeset) do
    validate_change(changeset, :day_of_week, fn :day_of_week, day ->
      if day in 1..7 do
        []
      else
        [day_of_week: "must be between 1 (Monday) and 7 (Sunday)"]
      end
    end)
  end

  @doc """
  Returns a human-readable day name for a day_of_week integer.
  """
  def day_name(1), do: "Monday"
  def day_name(2), do: "Tuesday"
  def day_name(3), do: "Wednesday"
  def day_name(4), do: "Thursday"
  def day_name(5), do: "Friday"
  def day_name(6), do: "Saturday"
  def day_name(7), do: "Sunday"
end
