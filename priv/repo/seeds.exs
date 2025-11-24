# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Adhdo.Repo.insert!(%Adhdo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Adhdo.Lists

# Clear existing data
Adhdo.Repo.delete_all(Adhdo.Lists.Task)
Adhdo.Repo.delete_all(Adhdo.Lists.TaskList)

# Morning Routine - Weekday
{:ok, _morning} =
  Lists.create_task_list_with_tasks(%{
    name: "Morning Routine",
    description: "Get ready for school!",
    tasks: [
      %{text: "Wake up and get out of bed"},
      %{text: "Use the bathroom"},
      %{text: "Brush teeth"},
      %{text: "Get dressed"},
      %{text: "Make bed"},
      %{text: "Eat breakfast"},
      %{text: "Clean up breakfast dishes"},
      %{text: "Pack backpack"},
      %{text: "Put on shoes"},
      %{text: "Grab lunch"}
    ]
  })

# Bedtime Routine
{:ok, _bedtime} =
  Lists.create_task_list_with_tasks(%{
    name: "Bedtime Routine",
    description: "Wind down for a good night's sleep",
    tasks: [
      %{text: "Clean up toys"},
      %{text: "Take a bath or shower"},
      %{text: "Put on pajamas"},
      %{text: "Brush teeth"},
      %{text: "Use the bathroom"},
      %{text: "Pack backpack for tomorrow"},
      %{text: "Read a book"},
      %{text: "Get in bed"}
    ]
  })

# After School
{:ok, _after_school} =
  Lists.create_task_list_with_tasks(%{
    name: "After School",
    description: "Come home and get settled",
    tasks: [
      %{text: "Put backpack in its place"},
      %{text: "Put lunch box in kitchen"},
      %{text: "Hang up coat"},
      %{text: "Put shoes away"},
      %{text: "Have a snack"},
      %{text: "Do homework"},
      %{text: "Practice instrument"},
      %{text: "Free time!"}
    ]
  })

# Homework Time
{:ok, _homework} =
  Lists.create_task_list_with_tasks(%{
    name: "Homework Time",
    description: "Get homework done!",
    tasks: [
      %{text: "Get homework folder"},
      %{text: "Sharpen pencils"},
      %{text: "Get water bottle"},
      %{text: "Math homework"},
      %{text: "Reading homework"},
      %{text: "Other homework"},
      %{text: "Put homework in backpack"},
      %{text: "Clean up workspace"}
    ]
  })

# Weekend Morning
{:ok, _weekend} =
  Lists.create_task_list_with_tasks(%{
    name: "Weekend Morning",
    description: "Start the weekend right!",
    tasks: [
      %{text: "Get out of bed"},
      %{text: "Use the bathroom"},
      %{text: "Brush teeth"},
      %{text: "Get dressed"},
      %{text: "Make bed"},
      %{text: "Eat breakfast"},
      %{text: "Clean up breakfast"}
    ]
  })

# Feed the Cat
{:ok, _cat} =
  Lists.create_task_list_with_tasks(%{
    name: "Feed the Cat",
    description: "Take care of our furry friend",
    tasks: [
      %{text: "Get cat food"},
      %{text: "Fill food bowl"},
      %{text: "Change water bowl"},
      %{text: "Put food away"},
      %{text: "Pet the cat!"}
    ]
  })

IO.puts("Seeded #{Adhdo.Repo.aggregate(Adhdo.Lists.TaskList, :count)} task lists")
IO.puts("Seeded #{Adhdo.Repo.aggregate(Adhdo.Lists.Task, :count)} tasks")
