class CreateWorkerJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :worker_jobs do |t|
      t.string :class_name
      t.string :status
      t.string :job_id
      t.integer :retry_count, default: 0
      t.jsonb :arguments
      t.string :job_errors, array: true, default: []
      t.datetime :triggered_at
      t.datetime :scheduled_at
      t.timestamps
    end
  end
end
