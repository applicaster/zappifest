module VersionHelper
  require 'Versionomy'

  module_function

  def check_version
    latest_zappifest_stable = parse_latest_zappifest_version_from_brew(`brew info zappifest`)
    prompt_for_update(latest_zappifest_stable) if update_required?(latest_zappifest_stable)
  rescue
    puts "Failed to check zappifest update - please check manually by running `brew info zappifest`"
  end

  def prompt_for_update(version)
    update_zappifest if agree update_message(version)
  end

  def update_required?(latest_zappifest_stable)
    Versionomy.parse(latest_zappifest_stable) > VERSION
  end

  def update_message(version)
    "A new zappifest version is available (#{version}). Do you want to upgrade ? (yes/no)"
  end

  def parse_latest_zappifest_version_from_brew(cmd)
    cmd.split("\n")[0].split(" ")[-1]
  end

  def update_zappifest
    puts "Updating zappifest..."
    system "brew update && brew upgrade zappifest"
  end
end
