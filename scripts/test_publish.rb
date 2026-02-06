#!/usr/bin/env ruby
require 'ostruct'
require 'json'
require 'fileutils'
require 'pp'

# Prepare a temporary manifest file using the provided example
manifest_json = %q({   "api": {     "class_name": "com.applicaster.reactnative.plugins.APReactNativeAdapter",     "react_packages": [       "com.applicaster.downloader.reactnative.DownloadManagerPackage"     ]   },   "dependency_repository_url": [],   "dependency_name": "@applicaster/offline-content-button",   "author_name": "Applicaster",   "author_email": "zapp@applicaster.com",   "name": "Offline Content Button Action",   "description": "Quick Brick Offline Content Button Action",   "type": "general",   "react_native": true,   "identifier": "offline-content-button",   "ui_builder_support": true,   "whitelisted_account_ids": [],   "deprecated_since_zapp_sdk": "",   "unsupported_since_zapp_sdk": "",   "general": {},   "targets": [     "mobile"   ],   "ui_frameworks": [     "quickbrick"   ],   "platform": "android_for_quickbrick",   "dependency_version": "15.0.0-rc.83",   "manifest_version": "15.0.0-rc.83",   "min_zapp_sdk": "13.4.0-dev",   "extra_dependencies": null,   "npm_dependencies": [     "@applicaster/offline-content-button@15.0.0-rc.83"   ],   "project_dependencies": [     {       "offline-content": "node_modules/@applicaster/offline-content-button/android"     }   ],   "custom_configuration_fields": [     {       "key": "android_assets_bundle",       "type": "uploader"     },     {       "type": "text",       "key": "is_loadable_mapper",       "tooltip_text": "Mapping key for extensions to check if entry can be loaded items",       "default": "extensions.hqme"     },     {       "type": "tag_select",       "key": "is_test_environment",       "tooltip_text": "If On all video entries will be marked as loadable",       "options": [         {           "text": "On",           "value": "on"         },         {           "text": "Off",           "value": "off"         }       ],       "initial_value": "off"     }   ],   "localizations": {     "fields": [       {         "type": "text_input",         "label": "Download label",         "key": "download_label",         "initial_value": "Download"       },       {         "type": "text_input",         "label": "Processing label",         "key": "processing_label",         "initial_value": "Preparing your download..."       }     ]   },   "characteristics": {     "applicaster": {       "quickbrick": {         "min_version": "15.0.0-rc.0"       }     }   } })

tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
FileUtils.mkdir_p(tmp_dir)
manifest_path = File.join(tmp_dir, 'test_manifest.json')
File.write(manifest_path, manifest_json)

puts "Created temp manifest at #{manifest_path}\n"

# Stub NetworkHelpers behavior to avoid external calls
module NetworkHelpers
  def self.validate_token(options)
    # Return an object with a body method that contains permissions for account '123'
    Struct.new(:body).new({
      "id" => 1,
      "email" => "test@example.com",
      "permissions" => [
        {
          "account_id" => (options.account || '123'),
          "roles" => ["zapp:plugin_developer"]
        }
      ]
    })
  end

  def self.get_accounts_list(options)
    Struct.new(:body).new([
      { "old_id" => (options.account || '123'), "name" => "Test Account" }
    ])
  end

  def self.get_request(url, params, options = {})
    # Provide minimal responses for targets and ui_frameworks endpoints used by PluginVersion
    if url.end_with?('/targets')
      Struct.new(:body).new([
        { 'id' => 1, 'name' => 'mobile' },
        { 'id' => 2, 'name' => 'tv' }
      ])
    elsif url.end_with?('/ui_frameworks')
      Struct.new(:body).new([
        { 'id' => 2, 'name' => 'quickbrick' },
        { 'id' => 3, 'name' => 'native' }
      ])
    else
      Struct.new(:body).new([])
    end
  end
end

# Now require the application pieces that rely on NetworkHelpers
require_relative '../lib/plugin_version'
require_relative '../lib/plugin'
require_relative '../lib/plugin_base'
require_relative '../lib/manifest_helpers'

# Monkeypatch PluginVersion#publish to avoid network calls and simulate success
class PluginVersion
  def publish
    # Simulate a Net::HTTPSuccess-like response
    success = Object.new
    def success.is_a?(klass)
      return true if klass == Net::HTTPSuccess
      super
    end
    def success.code; '200'; end
    def success.body; 'OK'; end
    success
  end

  # Monkeypatch show_diff to avoid interactive prompt during tests
  def show_diff
    puts "[#{@manifest && @manifest['name'] ? @manifest['name'] : 'manifest'}] show_diff called (simulated)"
  end
end

# Provide cached_data per the new implementation
cached_data = {
  targets: [ { "id" => 1, "name" => "mobile" } ],
  ui_frameworks: [ { "id" => 2, "name" => "quickbrick" } ]
}

# Build options as OpenStruct (mimics Commander options object)
base_options = OpenStruct.new(
  access_token: 'dummy',
  base_url: 'https://zapp.applicaster.com/api/v1/admin',
  accounts_url: 'https://accounts.applicaster.com/api/v1',
  account: '123',
  plugin_id: nil,
  plugin_guide: nil,
  plugin_about: nil,
  new: true, # avoid zapp_plugin network lookup
  manifest: nil,
  parallel: nil
)

# Define local process_single_manifest to mirror lib/zappifest.rb implementation
require 'net/http'

def process_single_manifest(path, options, cached_data)
  begin
    local_options = options.dup
    local_options.manifest = path
    local_options.instance_variable_set(:@cached_metadata, cached_data)

    puts "[#{path}] Gathering plugin information..."
    plugin_version = PluginVersion.new(local_options)

    if plugin_version.existing_plugin && plugin_version.existing_plugin["owner_account_id"] != local_options.account
      puts "[#{path}] You are not authorized to update this plugin"
      return
    end

    diff_keys = plugin_version.manifest.keys - ManifestHelpers.whitelisted_keys
    missing_keys = ManifestHelpers.mandatory_keys(local_options.new) - plugin_version.manifest.keys

    if diff_keys.any?
      puts "[#{path}] Validation failed: Manifest contains unpermitted keys: #{diff_keys.to_s}"
      return
    end

    if missing_keys.any?
      puts "[#{path}] Validation failed: Manifest missing mandatory keys: #{missing_keys.to_s}"
      return
    end

    # Show diff unless explicitly disabled and if plugin exists (simulate existing plugin when plugin_id present)
    if plugin_version.id && !local_options.respond_to?(:no_diff) || (plugin_version.id && local_options.respond_to?(:no_diff) && !local_options.no_diff)
      plugin_version.show_diff
    end

    puts "[#{path}] Publishing..."
    response = plugin_version.publish

    if response.is_a?(Net::HTTPSuccess)
      puts "[#{path}] Plugin successfully published!"
    else
      code = response.respond_to?(:code) ? response.code : 'N/A'
      body = response.respond_to?(:body) ? response.body : response.to_s
      puts "[#{path}] Failed: #{code} - #{body}"
    end

  rescue => e
    puts "[#{path}] Critical Error: #{e.message}"
  end
end

# Test sequential single manifest (legacy --manifest)
puts "=== Sequential legacy (--manifest) test ==="
opts1 = base_options.dup
opts1.manifest = manifest_path
opts1.plugin_id = nil
process_single_manifest(manifest_path, opts1, cached_data)

# Test sequential positional (same behavior)
puts "\n=== Sequential positional args test ==="
opts2 = base_options.dup
opts2.manifest = nil
opts2.plugin_id = nil
process_single_manifest(manifest_path, opts2, cached_data)

# Test show_diff behavior when plugin exists and no_diff false
puts "\n=== show_diff called when plugin_id present and no_diff false ==="
opts3 = base_options.dup
opts3.manifest = manifest_path
opts3.plugin_id = 'existing'
opts3.no_diff = false
process_single_manifest(manifest_path, opts3, cached_data)

# Test no_diff true skips show_diff
puts "\n=== no_diff true skips show_diff ==="
opts4 = base_options.dup
opts4.manifest = manifest_path
opts4.plugin_id = 'existing'
opts4.no_diff = true
process_single_manifest(manifest_path, opts4, cached_data)

# Test parallel: run two copies in parallel to exercise thread-safety of local_options
puts "\n=== Parallel test (2 threads) ==="
require 'parallel'
Parallel.each([manifest_path, manifest_path], in_threads: 2) do |p|
  opts = base_options.dup
  opts.manifest = p
  process_single_manifest(p, opts, cached_data)
end

puts "\nAll tests completed."
