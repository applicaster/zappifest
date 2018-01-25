class VersionHelper
  require 'Versionomy'

  def initialize(command)
    @command = command
  end

  def check_version
    color "Checking for zappifest update...", :green
    latest_zappifest_stable = parse_latest_zappifest_version(`brew info zappifest`)
    prompt_for_update(latest_zappifest_stable) if update_required?(latest_zappifest_stable)
  rescue
    puts "Failed to check zappifest update - please check manually by running `brew info zappifest`"
  end

  private

  def prompt_for_update(version)
    if agree update_message(version)
      update_zappifest
    elsif @command.name == "publish"
      puts "You need to update to the latest version in order to publish"
      exit
    end
  end

  def update_required?(latest_zappifest_stable)
    Versionomy.parse(latest_zappifest_stable) > VERSION
  end

  def update_message(version)
    "A new zappifest version is available (#{version}). Do you want to upgrade ? (yes/no)"
  end

  def parse_latest_zappifest_version(cmd)
    cmd.split("\n")[0].split(" ")[-1]
  end

  def update_zappifest
    puts "Updating zappifest..."
    system "brew update && brew upgrade zappifest"
  end
end
