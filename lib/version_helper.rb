class VersionHelper
  require 'versionomy'

  def initialize(command)
    @command = command
  end

  def check_version
    color "Checking for zappifest update...", :green
    zappifest_tap = `curl https://raw.githubusercontent.com/applicaster/homebrew-tap/master/zappifest.rb`
    @latest_zappifest_stable = zappifest_tap.scan(/version \".+\"/).first.split(" ")[-1].delete("\"")
    prompt_for_update if update_required?
  rescue
    puts "Failed to check zappifest update - please check manually by running `brew info zappifest`"
  end

  private

  def prompt_for_update
    if agree update_message
      update_zappifest
    elsif @command.name == "publish"
      puts "You need to update to the latest version in order to publish a plugin"
      exit
    end
  end

  def update_required?
    Versionomy.parse(@latest_zappifest_stable) > VERSION
  end

  def update_message
    "A new zappifest version is available (#{@latest_zappifest_stable}). Do you want to upgrade ? (yes/no)"
  end

  def update_zappifest
    puts "Updating zappifest..."
    system "brew update && brew upgrade zappifest"
  end
end
