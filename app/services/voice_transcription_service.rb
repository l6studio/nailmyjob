# frozen_string_literal: true

class VoiceTranscriptionService
  DEEPGRAM_API_URL = "https://api.deepgram.com/v1/listen"

  def initialize(audio_file)
    @audio_file = audio_file
  end

  def transcribe
    if ENV["DEEPGRAM_API_KEY"].blank?
      if Rails.env.development?
        return mock_transcription
      else
        Rails.logger.error("DEEPGRAM_API_KEY is not configured")
        return { success: false, error: "Voice transcription is not configured. Please set DEEPGRAM_API_KEY." }
      end
    end

    response = connection.post do |req|
      req.url DEEPGRAM_API_URL
      req.headers["Authorization"] = "Token #{ENV['DEEPGRAM_API_KEY']}"
      req.headers["Content-Type"] = content_type
      req.params = transcription_params
      req.body = audio_data
    end

    handle_response(response)
  rescue Faraday::Error => e
    Rails.logger.error("Deepgram API error: #{e.message}")
    { success: false, error: e.message }
  end

  private

  def connection
    @connection ||= Faraday.new do |f|
      f.request :retry, max: 2, interval: 0.5
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def transcription_params
    {
      model: "nova-2",
      smart_format: true,
      punctuate: true,
      paragraphs: true,
      diarize: false,
      language: "en-US"
    }
  end

  def content_type
    return "audio/wav" if @audio_file.content_type.blank?

    @audio_file.content_type
  end

  def audio_data
    @audio_file.download
  end

  def handle_response(response)
    if response.success?
      transcript = response.body.dig("results", "channels", 0, "alternatives", 0, "transcript")
      confidence = response.body.dig("results", "channels", 0, "alternatives", 0, "confidence")

      {
        success: true,
        transcript: transcript,
        confidence: confidence,
        raw_response: response.body
      }
    else
      {
        success: false,
        error: response.body["error"] || "Unknown error",
        status: response.status
      }
    end
  end

  def mock_transcription
    # For development without API key
    {
      success: true,
      transcript: "Kitchen remodel for John Smith at 123 Main Street. Medium kitchen, about 150 square feet. Mid-range shaker cabinets in white, quartz counters. They're keeping the fridge but need new stove and dishwasher. Full gut demo.",
      confidence: 0.92
    }
  end
end
