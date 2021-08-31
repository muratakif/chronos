class Scheduler
  DEFAULT_POLL_FREQUENCY = 1

  attr_reader :last_polled_at
  attr_reader :poll_frequency

  def initialize(poll_frequency = DEFAULT_POLL_FREQUENCY)
    @last_polled_at = nil
    @poll_frequency = poll_frequency
  end

  def throttle_workers
    while true
      poll_jobs
      sleep @poll_frequency
    end
  end

  def poll_jobs
    jobs = if @last_polled_at
       WorkerJob.where("status in (?) and scheduled_at < ?",  ['pending', 'retry'], @last_polled_at)
    else
       WorkerJob.all
    end

    # TODO: Make it multi-threaded
    jobs.each do |job|
      worker = job.class_name.constantize.new(job.job_id)
      worker.perform_now(*job.arguments.split(BaseWorker::JOIN_KEYWORD))
    rescue StandardError => e
      puts "Worker with ID: #{worker.job_id} has failed! Errors: #{e.message}"
    end

    @last_polled_at = Time.now
  end
end
