Rails.application.config.to_prepare do
  SolidQueue::Record.connects_to database: { writing: :queue }
end
