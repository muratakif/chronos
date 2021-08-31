class SimpleWorker < BaseWorker

  def perform(param1, param2)
   puts "here's param1: #{param1} and param2: #{param1}"
   raise 'jesus!'
  end
end

