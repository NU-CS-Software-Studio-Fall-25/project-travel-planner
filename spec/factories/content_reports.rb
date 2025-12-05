FactoryBot.define do
  factory :content_report do
    user { nil }
    reportable { nil }
    reason { "MyText" }
    report_type { "MyString" }
    status { "MyString" }
    reviewed_by { 1 }
    reviewed_at { "2025-12-05 14:28:19" }
    resolution_notes { "MyText" }
  end
end
