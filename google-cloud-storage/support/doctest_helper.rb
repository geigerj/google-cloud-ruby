# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/cloud/storage"
require "google/cloud/pubsub"

class File
  def self.file? f
    true
  end
  def self.readable? f
    true
  end
  def self.read *args
    "fake file data"
  end
end

class OpenSSL::PKey::RSA
  def self.new *args
    "rsa key"
  end
end

module Google
  module Cloud
    module Storage
      class Project
        def signed_url bucket, path, method: nil, expires: nil,
                       content_type: nil, content_md5: nil, headers: nil,
                       issuer: nil, client_email: nil, signing_key: nil,
                       private_key: nil
          # no-op stub, but ensures that calls match this copied signature
        end
      end
      class Bucket
        def signed_url path, method: nil, expires: nil, content_type: nil,
                       content_md5: nil, headers: nil, issuer: nil,
                       client_email: nil, signing_key: nil, private_key: nil
          # no-op stub, but ensures that calls match this copied signature
        end

        def post_object path, policy: nil, issuer: nil,
                        client_email: nil, signing_key: nil,
                        private_key: nil
          Google::Cloud::Storage::PostObject.new "https://storage.googleapis.com",
            { key: "my-todo-app/avatars/heidi/400x400.png",
              GoogleAccessId: "0123456789@gserviceaccount.com",
              signature: "ABC...XYZ=",
              policy: "ABC...XYZ=" }
        end
      end
      class File
        def download path = nil, verify: :md5, encryption_key: nil
          # no-op stub, but ensures that calls match this copied signature
          return StringIO.new("Hello world!") if path.nil?
        end
        def signed_url method: nil, expires: nil, content_type: nil,
                       content_md5: nil, headers: nil, issuer: nil,
                       client_email: nil, signing_key: nil, private_key: nil
          # no-op stub, but ensures that calls match this copied signature
        end
      end
    end
  end
end

module Google
  module Cloud
    module Storage
      def self.stub_new
        define_singleton_method :new do |*args|
          yield *args
        end
      end
      # Create default unmocked methods that will raise if ever called
      def self.new *args
        raise "This code example is not yet mocked"
      end
      class Credentials
        # Override the default constructor
        def self.new *args
          OpenStruct.new(client: OpenStruct.new(updater_proc: Proc.new {}))
        end
      end
    end
  end
end

module Google
  module Cloud
    module Pubsub
      def self.stub_new
        define_singleton_method :new do |*args|
          yield *args
        end
      end
      # Create default unmocked methods that will raise if ever called
      def self.new *args
        raise "This code example is not yet mocked"
      end
    end
  end
end

def mock_storage
  Google::Cloud::Storage.stub_new do |*args|
    credentials = OpenStruct.new(client: OpenStruct.new(updater_proc: Proc.new {}))
    storage = Google::Cloud::Storage::Project.new(Google::Cloud::Storage::Service.new("my-project", credentials))

    storage.service.mocked_service = Minitest::Mock.new

    yield storage.service.mocked_service if block_given?

    storage
  end
end

def mock_pubsub
  Google::Cloud::Pubsub.stub_new do |*args|
    credentials = OpenStruct.new(client: OpenStruct.new(updater_proc: Proc.new {}))
    pubsub = Google::Cloud::Pubsub::Project.new(Google::Cloud::Pubsub::Service.new("my-project", credentials))

    pubsub.service.mocked_publisher = Minitest::Mock.new
    pubsub.service.mocked_subscriber = Minitest::Mock.new
    if block_given?
      yield pubsub.service.mocked_publisher, pubsub.service.mocked_subscriber
    end

    pubsub
  end
end

YARD::Doctest.configure do |doctest|
  # Current mocking does not support testing GAPIC layer. (Auth failures occur.)
  doctest.skip "Google::Cloud::Storage::V1beta1::SpeechClient"

  # Skip all aliases, since tests would be exact duplicates
  doctest.skip "Google::Cloud::Storage::Bucket#new_file"
  doctest.skip "Google::Cloud::Storage::Bucket#find_files"
  doctest.skip "Google::Cloud::Storage::Bucket#combine"
  doctest.skip "Google::Cloud::Storage::Bucket#compose_file"
  doctest.skip "Google::Cloud::Storage::Bucket#new_notification"
  doctest.skip "Google::Cloud::Storage::Bucket#find_notification"
  doctest.skip "Google::Cloud::Storage::Bucket#find_notifications"
  doctest.skip "Google::Cloud::Storage::Project#find_bucket"
  doctest.skip "Google::Cloud::Storage::Project#find_buckets"

  doctest.before "Google::Cloud.storage" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud#storage" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage.new" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.skip "Google::Cloud::Storage::Credentials" # occasionally getting "This code example is not yet mocked"

  # Bucket

  doctest.before "Google::Cloud::Storage::Bucket" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#cors" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :patch_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#compose" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :compose_object, file_gapi, ["my-bucket", "path/to/new-file.ext", Google::Apis::StorageV1::ComposeRequest, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#update" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :patch_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :delete_bucket, nil, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#files" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#create_file" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_object, file_gapi, ["my-bucket", Google::Apis::StorageV1::Object, Hash]
      # Following expectation is only used in last example
      mock.expect :get_object, file_gapi, ["my-bucket", "destination/path/file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#create_notification" do
    mock_pubsub do |mock_publisher, mock_subscriber|
      mock_publisher.expect :create_topic, topic_gapi, ["projects/my-project/topics/my-topic", Hash]
      mock_publisher.expect :get_iam_policy, policy_gapi, ["projects/my-project/topics/my-topic", Hash]
      mock_publisher.expect :set_iam_policy, policy_gapi, ["projects/my-project/topics/my-topic", Google::Iam::V1::Policy, Hash]
    end
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_notification, notification_gapi, ["my-bucket", Google::Apis::StorageV1::Notification, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#upload_file" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_object, file_gapi, ["my-bucket", Google::Apis::StorageV1::Object, Hash]
      # Following expectation is only used in last example
      mock.expect :get_object, file_gapi, ["my-bucket", "destination/path/file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#signed_url" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#acl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :insert_bucket_access_control, object_access_control_gapi, ["my-todo-app", Google::Apis::StorageV1::BucketAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#acl@Or, grant access via a predefined permissions list:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-todo-app", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#default_acl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :insert_default_object_access_control, object_access_control_gapi, ["my-todo-app", Google::Apis::StorageV1::ObjectAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#default_acl@Or, grant access via a predefined permissions list:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-todo-app", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#notification" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_notification, notification_gapi, ["my-bucket", "1", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#notifications" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :list_notifications, list_notifications_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#policy" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#policy@Retrieve the latest policy and update it in a block:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
      mock.expect :set_bucket_iam_policy, new_policy_gapi, ["my-todo-app", Google::Apis::StorageV1::Policy, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#policy=" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
      mock.expect :set_bucket_iam_policy, new_policy_gapi, ["my-todo-app", Google::Apis::StorageV1::Policy, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#requester_pays" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, bucket_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#user_project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["other-project-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#test_permissions" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
      mock.expect :test_bucket_iam_permissions, permissions_gapi, ["my-todo-app", ["storage.buckets.get", "storage.buckets.delete"], Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket#user_project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["other-project-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  # Bucket::Acl

  doctest.before "Google::Cloud::Storage::Bucket::Acl#reload!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      access_controls = Google::Apis::StorageV1::BucketAccessControls.from_json(random_bucket_acl_hash("my-bucket").to_json)
      mock.expect :list_bucket_access_controls, access_controls, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      access_controls = Google::Apis::StorageV1::BucketAccessControls.from_json(random_bucket_acl_hash("my-bucket").to_json)
      mock.expect :list_bucket_access_controls, access_controls, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#add_owner" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_bucket_access_control, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::BucketAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#add_writer" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_bucket_access_control, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::BucketAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#add_reader" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_bucket_access_control, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::BucketAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :delete_bucket_access_control, true, ["my-bucket", "user-heidi@example.net", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#auth" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#private" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#project_private!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#projectPrivate!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#public" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#public_write!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Acl#publicReadWrite!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  # Bucket::DefaultAcl

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      access_controls = Google::Apis::StorageV1::ObjectAccessControls.from_json(random_default_acl_hash("my-bucket").to_json)
      mock.expect :list_default_object_access_controls, access_controls, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#add_" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_default_object_access_control, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::ObjectAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :delete_default_object_access_control, true, ["my-bucket", "user-heidi@example.net", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#auth" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#owner_full!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#bucketOwnerFullControl!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#owner_read!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#bucketOwnerRead!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#private" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::DefaultAcl#public" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, object_access_control_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  # Bucket::Cors

  doctest.before "Google::Cloud::Storage::Bucket::Cors" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :patch_bucket, bucket_gapi, ["my-bucket", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Bucket::Cors#add_rule" do
    mock_storage do |mock|
      mock.expect :insert_bucket, bucket_gapi, ["my-project", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  # Bucket::List

  doctest.before "Google::Cloud::Storage::Bucket::List" do
    mock_storage do |mock|
      mock.expect :list_buckets, list_buckets_gapi, ["my-project", Hash]
    end
  end

  # Bucket::Policy

  doctest.before "Google::Cloud::Storage::Policy" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
      mock.expect :set_bucket_iam_policy, new_policy_gapi, ["my-todo-app", Google::Apis::StorageV1::Policy, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Policy#role" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_bucket_iam_policy, policy_gapi, ["my-todo-app", Hash]
      mock.expect :set_bucket_iam_policy, new_policy_gapi, ["my-todo-app", Google::Apis::StorageV1::Policy, Hash]
    end
  end

  # File

  doctest.before "Google::Cloud::Storage::File" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#generations" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#update" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#copy" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :rewrite_object, done_rewrite(file_gapi), ["my-bucket", "path/to/my-file.ext", "new-destination-bucket", "path/to/destination/file.ext", nil, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#copy@The file can be copied to a new path in the current bucket:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :rewrite_object, done_rewrite(file_gapi), ["my-bucket", "path/to/my-file.ext", "my-bucket", "path/to/destination/file.ext", nil, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#copy@The file can also be copied by specifying a generation:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :rewrite_object, done_rewrite(file_gapi), ["my-bucket", "path/to/my-file.ext", "my-bucket", "copy/of/previous/generation/file.ext", nil, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#copy@The file can be modified during copying:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :rewrite_object, done_rewrite(file_gapi), ["my-bucket", "path/to/my-file.ext", "new-destination-bucket", "path/to/destination/file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#rotate" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :rewrite_object, OpenStruct.new(done: true, resource: file_gapi), ["my-bucket", "path/to/my-file.ext", "my-bucket", "path/to/my-file.ext", nil, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :delete_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#download@Download to an in-memory StringIO object." do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#public_url" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_object, file_gapi, ["my-todo-app", "avatars/heidi/400x400.png", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#url" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_object, file_gapi, ["my-todo-app", "avatars/heidi/400x400.png", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#user_project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["other-project-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/file.ext", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#acl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_object, file_gapi, ["my-todo-app", "avatars/heidi/400x400.png", Hash]
      mock.expect :insert_object_access_control, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::ObjectAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#acl@Or, grant access via a predefined permissions list:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_object, file_gapi, ["my-todo-app", "avatars/heidi/400x400.png", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File#signed_url" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      mock.expect :get_object, file_gapi, ["my-todo-app", "avatars/heidi/400x400.png", Hash]
    end
  end

  # File::Acl

  doctest.before "Google::Cloud::Storage::File::Acl" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      access_controls = Google::Apis::StorageV1::ObjectAccessControls.from_json(random_file_acl_hash("my-bucket", "path/to/my-file.ext").to_json)
      mock.expect :list_object_access_controls, access_controls, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#add_owner" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :insert_object_access_control, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::ObjectAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#add_reader" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :insert_object_access_control, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::ObjectAccessControl, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :delete_object_access_control, true, ["my-bucket", "path/to/my-file.ext", "user-heidi@example.net", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#auth" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#owner_full!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#bucketOwnerFullControl!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#owner_read!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#bucketOwnerRead!" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#private" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::File::Acl#public" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :patch_object, object_access_control_gapi, ["my-bucket", "path/to/my-file.ext", Google::Apis::StorageV1::Object, Hash]
    end
  end

  # File::List

  doctest.before "Google::Cloud::Storage::File::List" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  # Notification

  doctest.before "Google::Cloud::Storage::Notification" do
    mock_pubsub do |mock_publisher, mock_subscriber|
      mock_publisher.expect :create_topic, topic_gapi, ["projects/my-project/topics/my-topic", Hash]
      mock_publisher.expect :get_iam_policy, policy_gapi, ["projects/my-project/topics/my-topic", Hash]
      mock_publisher.expect :set_iam_policy, policy_gapi, ["projects/my-project/topics/my-topic", Google::Iam::V1::Policy, Hash]
    end
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :insert_notification, notification_gapi, ["my-bucket", Google::Apis::StorageV1::Notification, Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Notification#delete" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_notification, notification_gapi, ["my-bucket", "1", Hash]
      mock.expect :delete_notification, nil, ["my-bucket", nil, Hash]
    end
  end

  # Project

  doctest.before "Google::Cloud::Storage::Project" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Project#bucket@With `user_project` set to bill costs to the default project:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["other-project-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Project#bucket@With `user_project` set to a project other than the default:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["other-project-bucket", Hash]
      mock.expect :list_objects, list_files_gapi, ["my-bucket", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Project#buckets" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :list_buckets, list_buckets_gapi, ["my-project", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Project#buckets@Retrieve buckets with names that begin with a given prefix:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :list_buckets, list_buckets_gapi, ["my-project", Hash]
    end
  end

  doctest.before "Google::Cloud::Storage::Project#create_bucket" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi, ["my-bucket", Hash]
      mock.expect :get_object, file_gapi, ["my-bucket", "path/to/my-file.ext", Hash]
      mock.expect :insert_bucket, bucket_gapi, ["my-project", Google::Apis::StorageV1::Bucket, Hash]
    end
  end

  # PostObject

  doctest.before "Google::Cloud::Storage::Bucket#post_object" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
    end
  end
  doctest.before "Google::Cloud::Storage::Bucket#post_object@Using a policy to define the upload authorization:" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
    end
  end
  doctest.before "Google::Cloud::Storage::Bucket#post_object@Using the issuer and signing_key options:" do
    mock_storage do |mock|
      OpenSSL::PKey::RSA.stub :new, "key" do
        mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
      end
    end
  end

  doctest.before "Google::Cloud::Storage::PostObject" do
    mock_storage do |mock|
      mock.expect :get_bucket, bucket_gapi("my-todo-app"), ["my-todo-app", Hash]
    end
  end

end

# Fixture helpers



def bucket_gapi name = "my-bucket"
  Google::Apis::StorageV1::Bucket.from_json random_bucket_hash(name).to_json
end

def list_buckets_gapi count = 2, token = nil
  buckets = count.times.map { bucket_gapi }
  Google::Apis::StorageV1::Buckets.new(
    kind: "storage#buckets", items: buckets, next_page_token: token
  )
end

def file_gapi bucket_name = "my-bucket", name = "path/to/my-file.ext"
  Google::Apis::StorageV1::Object.from_json random_file_hash(bucket_name, name).to_json
end

def list_files_gapi count = 2, token = nil, prefixes = nil
  files = count.times.map { file_gapi }
  Google::Apis::StorageV1::Objects.new kind: "storage#objects", items: files, next_page_token: token, prefixes: prefixes
end

def object_access_control_gapi
  entity = "project-owners-1234567890"
  Google::Apis::StorageV1::ObjectAccessControl.new entity: entity
end

def done_rewrite gapi
  Google::Apis::StorageV1::RewriteResponse.new done: true, resource: gapi
end

def random_bucket_hash(name = "my-bucket",
  url_root="https://www.googleapis.com/storage/v1", location="US",
  storage_class="STANDARD", versioning=nil, logging_bucket=nil,
  logging_prefix=nil, website_main=nil, website_404=nil)
  versioning_config = { "enabled" => versioning } if versioning
  { "kind" => "storage#bucket",
    "id" => name,
    "selfLink" => "#{url_root}/b/#{name}",
    "projectNumber" => "1234567890",
    "name" => name,
    "timeCreated" => Time.now,
    "metageneration" => "1",
    "owner" => { "entity" => "project-owners-1234567890" },
    "location" => location,
    "cors" => [{"origin"=>["http://example.org"], "method"=>["GET","POST","DELETE"], "responseHeader"=>["X-My-Custom-Header"], "maxAgeSeconds"=>3600},{"origin"=>["http://example.org"], "method"=>["GET","POST","DELETE"], "responseHeader"=>["X-My-Custom-Header"], "maxAgeSeconds"=>3600}],
    "logging" => logging_hash(logging_bucket, logging_prefix),
    "storageClass" => storage_class,
    "versioning" => versioning_config,
    "website" => website_hash(website_main, website_404),
    "etag" => "CAE=" }.delete_if { |_, v| v.nil? }
end

def logging_hash(bucket, prefix)
  { "logBucket"       => bucket,
    "logObjectPrefix" => prefix,
  }.delete_if { |_, v| v.nil? } if bucket || prefix
end

def website_hash(website_main, website_404)
  { "mainPageSuffix" => website_main,
    "notFoundPage"   => website_404,
  }.delete_if { |_, v| v.nil? } if website_main || website_404
end

def random_file_hash bucket, name, generation="1234567890"
  { "kind" => "storage#object",
    "id" => "#{bucket}/#{name}/1234567890",
    "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket}/o/#{name}",
    "name" => "#{name}",
    "timeCreated" => Time.now,
    "bucket" => "#{bucket}",
    "generation" => generation,
    "metageneration" => "1",
    "cacheControl" => "public, max-age=3600",
    "contentDisposition" => "attachment; filename=filename.ext",
    "contentEncoding" => "gzip",
    "contentLanguage" => "en",
    "contentType" => "text/plain",
    "updated" => Time.now,
    "storageClass" => "STANDARD",
    "size" => rand(10_000),
    "md5Hash" => "HXB937GQDFxDFqUGi//weQ==",
    "mediaLink" => "https://www.googleapis.com/download/storage/v1/b/#{bucket}/o/#{name}?generation=1234567890&alt=media",
    "metadata" => { "player" => "Alice", "score" => "101" },
    "owner" => { "entity" => "user-1234567890", "entityId" => "abc123" },
    "crc32c" => "Lm1F3g==",
    "etag" => "CKih16GjycICEAE=" }
end

def random_bucket_acl_hash bucket_name
  {
   "kind" => "storage#bucketAccessControls",
   "items" => [
    {
     "kind" => "storage#bucketAccessControl",
     "id" => "#{bucket_name}-UUID/project-owners-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}-UUID/acl/project-owners-1234567890",
     "bucket" => "#{bucket_name}-UUID",
     "entity" => "project-owners-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "owners"
     },
     "etag" => "CAE="
    },
    {
     "kind" => "storage#bucketAccessControl",
     "id" => "#{bucket_name}-UUID/project-editors-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}-UUID/acl/project-editors-1234567890",
     "bucket" => "#{bucket_name}-UUID",
     "entity" => "project-editors-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "editors"
     },
     "etag" => "CAE="
    },
    {
     "kind" => "storage#bucketAccessControl",
     "id" => "#{bucket_name}-UUID/project-viewers-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}-UUID/acl/project-viewers-1234567890",
     "bucket" => "#{bucket_name}-UUID",
     "entity" => "project-viewers-1234567890",
     "role" => "READER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "viewers"
     },
     "etag" => "CAE="
    }
   ]
  }
end

def random_default_acl_hash bucket_name
  {
   "kind" => "storage#objectAccessControls",
   "items" => [
    {
     "kind" => "storage#objectAccessControl",
     "entity" => "project-owners-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "owners"
     },
     "etag" => "CAE="
    },
    {
     "kind" => "storage#objectAccessControl",
     "entity" => "project-editors-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "editors"
     },
     "etag" => "CAE="
    },
    {
     "kind" => "storage#objectAccessControl",
     "entity" => "project-viewers-1234567890",
     "role" => "READER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "viewers"
     },
     "etag" => "CAE="
    }
   ]
  }
end

def random_file_acl_hash bucket_name, file_name
  {
   "kind" => "storage#objectAccessControls",
   "items" => [
    {
     "kind" => "storage#objectAccessControl",
     "id" => "#{bucket_name}/#{file_name}/123/project-owners-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}/o/#{file_name}/acl/project-owners-1234567890",
     "bucket" => "#{bucket_name}",
     "object" => "#{file_name}",
     "generation" => "123",
     "entity" => "project-owners-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "owners"
     },
     "etag" => "abcDEF123="
    },
    {
     "kind" => "storage#objectAccessControl",
     "id" => "#{bucket_name}/#{file_name}/123/project-editors-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}/o/#{file_name}/acl/project-editors-1234567890",
     "bucket" => "#{bucket_name}",
     "object" => "#{file_name}",
     "generation" => "123",
     "entity" => "project-editors-1234567890",
     "role" => "OWNER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "editors"
     },
     "etag" => "abcDEF123="
    },
    {
     "kind" => "storage#objectAccessControl",
     "id" => "#{bucket_name}/#{file_name}/123/project-viewers-1234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}/o/#{file_name}/acl/project-viewers-1234567890",
     "bucket" => "#{bucket_name}",
     "object" => "#{file_name}",
     "generation" => "123",
     "entity" => "project-viewers-1234567890",
     "role" => "READER",
     "projectTeam" => {
      "projectNumber" => "1234567890",
      "team" => "viewers"
     },
     "etag" => "abcDEF123="
    },
    {
     "kind" => "storage#objectAccessControl",
     "id" => "#{bucket_name}/#{file_name}/123/user-12345678901234567890",
     "selfLink" => "https://www.googleapis.com/storage/v1/b/#{bucket_name}/o/#{file_name}/acl/user-12345678901234567890",
     "bucket" => "#{bucket_name}",
     "object" => "#{file_name}",
     "generation" => "123",
     "entity" => "user-12345678901234567890",
     "role" => "OWNER",
     "entityId" => "12345678901234567890",
     "etag" => "abcDEF123="
    }
   ]
  }
end

def policy_gapi
  Google::Apis::StorageV1::Policy.new(
    etag: "CAE=",
    bindings: [
      Google::Apis::StorageV1::Policy::Binding.new(
        role: "roles/storage.objectViewer",
        members: [
          "user:viewer@example.com"
        ]
      )
    ]
  )
end

def new_policy_gapi
  Google::Apis::StorageV1::Policy.new(
    etag: "CAE=",
    bindings: [
      Google::Apis::StorageV1::Policy::Binding.new(
        role: "roles/storage.objectViewer",
        members: [
          "user:viewer@example.com",
          "serviceAccount:1234567890@developer.gserviceaccount.com"
        ]
      )
    ]
  )
end

def permissions_gapi
  Google::Apis::StorageV1::TestIamPermissionsResponse.new(
    permissions: ["storage.buckets.get"]
  )
end

def notification_gapi
  Google::Apis::StorageV1::Notification.new(
    payload_format: "JSON_API_V1",
    topic: "my-topic"
  )
end

def list_notifications_gapi count = 2
  notifications = count.times.map { notification_gapi }
  Google::Apis::StorageV1::Notifications.new kind: "storage#notifications", items: notifications
end

def topic_gapi topic_name = "my-topic"
  Google::Pubsub::V1::Topic.new name: topic_path(topic_name)
end

def policy_gapi
  Google::Iam::V1::Policy.new(
    bindings: []
  )
end

def project_path
  "projects/my-project"
end

def topic_path topic_name
  "#{project_path}/topics/#{topic_name}"
end
