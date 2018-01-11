# Copyright 2017 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# AUTO GENERATED BY GAPIC

require "minitest/autorun"
require "minitest/spec"

require "google/cloud/language"

describe "LanguageServiceSmokeTest" do
  it "runs one smoke test with analyze_sentiment" do

    language_service_client = Google::Cloud::Language.new
    content = "Hello, world!"
    type = :PLAIN_TEXT
    document = { content: content, type: type }
    response = language_service_client.analyze_sentiment(document)
  end
end
