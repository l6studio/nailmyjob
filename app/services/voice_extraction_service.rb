# frozen_string_literal: true

class VoiceExtractionService
  EXTRACTION_PROMPT = <<~PROMPT
    You are an expert at extracting structured data from contractor voice notes about home remodeling projects.

    Extract the following information from the transcript:
    - client_name: The client's name (homeowner)
    - project_address: The project address
    - project_city: City (if mentioned)
    - project_state: State (if mentioned)
    - template_type: "kitchen", "bathroom", or "custom"
    - project_size: "small", "medium", or "large" based on context
    - line_items: Array of items mentioned with category, description, quality_tier

    Categories for line_items: cabinets, countertops, flooring, backsplash, appliances, plumbing, electrical, demo, labor, permits, other

    Quality tiers: "good" (budget/basic), "better" (mid-range), "best" (premium/high-end)

    Return JSON only. For each field, include a confidence score (0.0-1.0).
    If information is not mentioned, set value to null and confidence to 0.

    Example output:
    {
      "client_name": { "value": "John Smith", "confidence": 0.95 },
      "project_address": { "value": "123 Main Street", "confidence": 0.90 },
      "project_city": { "value": null, "confidence": 0 },
      "project_state": { "value": null, "confidence": 0 },
      "template_type": { "value": "kitchen", "confidence": 0.98 },
      "project_size": { "value": "medium", "confidence": 0.85 },
      "line_items": [
        {
          "category": "cabinets",
          "description": "White shaker cabinets",
          "quality_tier": "better",
          "confidence": 0.88
        }
      ]
    }
  PROMPT

  def initialize(transcript)
    @transcript = transcript
  end

  def extract
    if ENV["OPENAI_API_KEY"].blank?
      if Rails.env.development?
        return mock_extraction
      else
        Rails.logger.error("OPENAI_API_KEY is not configured")
        return { success: false, error: "AI extraction is not configured. Please set OPENAI_API_KEY." }
      end
    end

    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: EXTRACTION_PROMPT },
          { role: "user", content: @transcript }
        ],
        response_format: { type: "json_object" },
        temperature: 0.3
      }
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error("OpenAI API error: #{e.message}")
    { success: false, error: e.message }
  end

  private

  def client
    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def handle_response(response)
    content = response.dig("choices", 0, "message", "content")
    return { success: false, error: "No content in response" } if content.blank?

    extracted_data = JSON.parse(content)
    average_confidence = calculate_average_confidence(extracted_data)

    {
      success: true,
      extracted_data: normalize_extracted_data(extracted_data),
      confidence_score: average_confidence
    }
  rescue JSON::ParserError => e
    { success: false, error: "Failed to parse JSON: #{e.message}" }
  end

  def calculate_average_confidence(data)
    confidences = []

    # Collect confidences from simple fields
    %w[client_name project_address project_city project_state template_type project_size].each do |field|
      confidence = data.dig(field, "confidence")
      confidences << confidence if confidence&.positive?
    end

    # Collect confidences from line items
    data["line_items"]&.each do |item|
      confidences << item["confidence"] if item["confidence"]&.positive?
    end

    return 0.0 if confidences.empty?

    confidences.sum / confidences.size
  end

  def normalize_extracted_data(data)
    {
      client_name: data.dig("client_name", "value"),
      project_address: data.dig("project_address", "value"),
      project_city: data.dig("project_city", "value"),
      project_state: data.dig("project_state", "value"),
      template_type: data.dig("template_type", "value"),
      project_size: data.dig("project_size", "value"),
      line_items: normalize_line_items(data["line_items"] || []),
      field_confidences: extract_confidences(data)
    }
  end

  def normalize_line_items(items)
    items.map do |item|
      {
        category: item["category"],
        description: item["description"],
        quality_tier: item["quality_tier"],
        confidence: item["confidence"]
      }
    end
  end

  def extract_confidences(data)
    confidences = {}

    %w[client_name project_address project_city project_state template_type project_size].each do |field|
      confidences[field] = data.dig(field, "confidence") || 0
    end

    confidences
  end

  def mock_extraction
    # For development without API key
    {
      success: true,
      extracted_data: {
        client_name: "John Smith",
        project_address: "123 Main Street",
        project_city: nil,
        project_state: nil,
        template_type: "kitchen",
        project_size: "medium",
        line_items: [
          { category: "cabinets", description: "White shaker cabinets, mid-range", quality_tier: "better", confidence: 0.88 },
          { category: "countertops", description: "Quartz counters", quality_tier: "better", confidence: 0.85 },
          { category: "appliances", description: "New stove and dishwasher, keeping fridge", quality_tier: "better", confidence: 0.80 },
          { category: "demo", description: "Full gut demo", quality_tier: nil, confidence: 0.92 }
        ],
        field_confidences: {
          client_name: 0.95,
          project_address: 0.90,
          project_city: 0,
          project_state: 0,
          template_type: 0.98,
          project_size: 0.85
        }
      },
      confidence_score: 0.88
    }
  end
end
