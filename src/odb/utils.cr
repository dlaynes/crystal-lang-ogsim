class Task
  @end : Time | Nil = nil

  def initialize(@label : String, @start : Time, @pos : Int32)
  end

  def stop
    @end = Time.now
  end

  def elapsedTime
    return @end.as(Time).epoch_ms - @start.epoch_ms
  end
end

class Profiler
  @pos = 0

  def initialize(@tasks : Hash(String, Task) = {} of String => Task)
  end

  def startTask(label : String)
    @tasks[label] = Task.new label, Time.now, @pos
    @pos = @pos + 1
  end

  def endTask(label : String)
    if !@tasks[label]?
      raise Exception.new "Task '" + label + "' not found."
    end

    @tasks[label].stop
  end

  def getTasks : Array(Task | Nil)
    taskList = Array(Task | Nil).new(@tasks.size) { nil }

    @tasks.each do |id, task|
      taskList[task.@pos] = task
    end
    taskList
  end
end
