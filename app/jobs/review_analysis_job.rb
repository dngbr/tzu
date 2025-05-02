require_relative '../services/reviews_analyzer'

class ReviewAnalysisJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  STATUS = {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # Store job status in Redis
  def self.set_status(job_id, status, result = nil)
    Sidekiq.redis do |conn|
      conn.hset("review_analysis:#{job_id}", 'status', status)
      conn.hset("review_analysis:#{job_id}", 'result', result.to_json) if result
      # Set expiration to 1 hour
      conn.expire("review_analysis:#{job_id}", 3600)
    end
  end

  # Get job status from Redis
  def self.get_status(job_id)
    Sidekiq.redis do |conn|
      status = conn.hget("review_analysis:#{job_id}", 'status')
      result = conn.hget("review_analysis:#{job_id}", 'result')
      result = JSON.parse(result) if result
      { status: status, result: result }
    end
  end

  def perform(company_id)
    # Set initial status
    self.class.set_status(jid, STATUS[:processing])
    
    # Find the company
    company = Company.find_by(id: company_id)
    unless company
      self.class.set_status(jid, STATUS[:failed], { error: 'Company not found' })
      return
    end
    
    # Check if analysis can be performed
    unless CompanyReviewAnalysis.can_analyze?(company)
      self.class.set_status(jid, STATUS[:failed], { error: 'Not enough reviews to analyze' })
      return
    end
    
    begin
      # Perform the analysis
      result = CompanyReviewAnalysis.perform_analysis(company)
      
      # Update status to completed
      self.class.set_status(jid, STATUS[:completed], { success: true })
    rescue => e
      Rails.logger.error("Error analyzing reviews for company #{company_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      self.class.set_status(jid, STATUS[:failed], { error: e.message })
    end
  end
end