class BaseWorker
  JOIN_KEYWORD = '###'.freeze
  DEFAULT_MAX_RETRY_CNT = 5

  attr_reader :status
  attr_reader :triggered_at
  attr_reader :errors
  attr_reader :scheduled_at
  attr_reader :job_id
  attr_reader :class_name

  # TODO: Implement retry mechanism
  def initialize(job_id = nil, status = 'pending', scheduled_at = Time.now)
    if job_id
      @worker_record = WorkerJob.find_by(job_id: job_id)
      @errors = []
    else
      init_vars(status, scheduled_at)
      @worker_record = WorkerJob.create(status: @status, scheduled_at: @scheduled_at, class_name: @class_name, job_id: @job_id)
    end
  end

  def schedule # Obsolete?
    @status = 'scheduled'
    @scheduled_at = Time.now
  end

  def perform_now(*args)
    @worker_record.status = @status = 'running'
    @worker_record.triggered_at = @triggered_at = Time.now
    self.perform(*args)
  rescue StandardError => error
    @errors << error
    @worker_record.job_errors = @errors
    retry_job
    raise error
  ensure
    ensure_record_valid
  end

  def perform_async(*args)
    @worker_record.update(arguments: args.join(JOIN_KEYWORD), status: @status, triggered_at: @triggered_at)
  end

  private

  def init_vars(status, scheduled_at)
    @status = status
    @scheduled_at = scheduled_at
    @class_name = self.class.name
    @triggered_at = nil
    @job_id = SecureRandom.uuid
    @errors = []
  end

  def retry_job
    if can_retry?
      @worker_record.update(status: 'retry', scheduled_at: schedule_time, retry_count: @worker_record.retry_count + 1)
    else
      @worker_record.update(status: 'exhausted')
    end
  end

  def ensure_record_valid
    @worker_record.status = 'done' if @errors.empty?
    @worker_record.save
  end

  def can_retry?
    @worker_record.retry_count < DEFAULT_MAX_RETRY_CNT
  end

  def schedule_time
    5.seconds.from_now # implement exponential backoff algorithm for scheduling jobs
  end
end
